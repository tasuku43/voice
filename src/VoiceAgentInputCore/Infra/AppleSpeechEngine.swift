import Foundation
import Speech

public final class AppleSpeechEngine: SpeechToTextEngine, @unchecked Sendable {
    public let localeIdentifier: String
    public let temporaryDirectory: URL
    public let requiresOnDeviceRecognition: Bool

    public init(
        localeIdentifier: String = "ja-JP",
        temporaryDirectory: URL = FileManager.default.temporaryDirectory,
        requiresOnDeviceRecognition: Bool = true
    ) {
        self.localeIdentifier = localeIdentifier
        self.temporaryDirectory = temporaryDirectory
        self.requiresOnDeviceRecognition = requiresOnDeviceRecognition
    }

    public func transcribe(audio: RecordedAudio) async throws -> Transcript {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) else {
            throw AppleSpeechEngineError.recognizerUnavailable(localeIdentifier: localeIdentifier)
        }
        guard recognizer.isAvailable else {
            throw AppleSpeechEngineError.recognizerUnavailable(localeIdentifier: localeIdentifier)
        }

        return try await TemporaryRecordedAudioFileStore(
            directoryURL: temporaryDirectory
        ).withRecordedAudioFile(audio) { url in
            try await withCheckedThrowingContinuation { continuation in
                let box = SpeechResultBox(continuation: continuation)
                let request = SFSpeechURLRecognitionRequest(url: url)
                request.shouldReportPartialResults = true
                request.requiresOnDeviceRecognition = requiresOnDeviceRecognition

                recognizer.recognitionTask(with: request) { result, error in
                    if let result {
                        box.storeLatest(result.bestTranscription.formattedString, localeIdentifier: self.localeIdentifier)
                    }

                    if let error {
                        let mappedError = AppleSpeechEngineError.map(error)
                        if case .noSpeechDetected = mappedError, box.resumeWithLatestTranscriptIfAvailable() {
                            return
                        }
                        box.resume(throwing: mappedError)
                        return
                    }

                    guard let result, result.isFinal else {
                        return
                    }

                    box.resume(returning: Transcript(
                        text: result.bestTranscription.formattedString,
                        localeIdentifier: self.localeIdentifier,
                        confidence: nil
                    ))
                }
            }
        }
    }

    public func transcribeMockText(_ text: String) async throws -> String {
        text
    }
}

public enum AppleSpeechEngineError: Error, Equatable {
    case recognizerUnavailable(localeIdentifier: String)
    case noSpeechDetected
    case transcriptionFailed(description: String)

    static func map(_ error: Error) -> AppleSpeechEngineError {
        let nsError = error as NSError
        if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 1110 {
            return .noSpeechDetected
        }
        return .transcriptionFailed(description: nsError.localizedDescription)
    }
}

private final class SpeechResultBox: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false
    private var latestTranscript: Transcript?
    private let continuation: CheckedContinuation<Transcript, Error>

    init(continuation: CheckedContinuation<Transcript, Error>) {
        self.continuation = continuation
    }

    func storeLatest(_ text: String, localeIdentifier: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        lock.lock()
        latestTranscript = Transcript(
            text: trimmed,
            localeIdentifier: localeIdentifier,
            confidence: nil
        )
        lock.unlock()
    }

    func resumeWithLatestTranscriptIfAvailable() -> Bool {
        lock.lock()
        let transcript = latestTranscript
        lock.unlock()

        guard let transcript else {
            return false
        }
        resume(returning: transcript)
        return true
    }

    func resume(returning transcript: Transcript) {
        guard markResumed() else {
            return
        }
        continuation.resume(returning: transcript)
    }

    func resume(throwing error: Error) {
        guard markResumed() else {
            return
        }
        continuation.resume(throwing: error)
    }

    private func markResumed() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if didResume {
            return false
        }
        didResume = true
        return true
    }
}

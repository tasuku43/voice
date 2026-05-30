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
                request.shouldReportPartialResults = false
                request.requiresOnDeviceRecognition = requiresOnDeviceRecognition

                recognizer.recognitionTask(with: request) { result, error in
                    if let error {
                        box.resume(throwing: error)
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
}

private final class SpeechResultBox: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false
    private let continuation: CheckedContinuation<Transcript, Error>

    init(continuation: CheckedContinuation<Transcript, Error>) {
        self.continuation = continuation
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

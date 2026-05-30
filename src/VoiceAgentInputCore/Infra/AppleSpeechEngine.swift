import Foundation
import Speech

public final class AppleSpeechEngine: SpeechToTextEngine, @unchecked Sendable {
    public let localeIdentifier: String
    public let temporaryDirectory: URL

    public init(localeIdentifier: String = "ja-JP", temporaryDirectory: URL = FileManager.default.temporaryDirectory) {
        self.localeIdentifier = localeIdentifier
        self.temporaryDirectory = temporaryDirectory
    }

    public func transcribe(audio: RecordedAudio) async throws -> Transcript {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) else {
            throw AppleSpeechEngineError.recognizerUnavailable(localeIdentifier: localeIdentifier)
        }
        guard recognizer.isAvailable else {
            throw AppleSpeechEngineError.recognizerUnavailable(localeIdentifier: localeIdentifier)
        }

        let url = temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")
        try audio.data.write(to: url, options: .atomic)

        return try await withCheckedThrowingContinuation { continuation in
            let box = SpeechResultBox(continuation: continuation) {
                try? FileManager.default.removeItem(at: url)
            }
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false

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
    private let cleanup: () -> Void

    init(continuation: CheckedContinuation<Transcript, Error>, cleanup: @escaping () -> Void) {
        self.continuation = continuation
        self.cleanup = cleanup
    }

    func resume(returning transcript: Transcript) {
        guard markResumed() else {
            return
        }
        cleanup()
        continuation.resume(returning: transcript)
    }

    func resume(throwing error: Error) {
        guard markResumed() else {
            return
        }
        cleanup()
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

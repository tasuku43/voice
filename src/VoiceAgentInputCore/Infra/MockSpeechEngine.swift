import Foundation

public protocol SpeechToTextEngine {
    func transcribe(audio: RecordedAudio) async throws -> Transcript
    func transcribeMockText(_ text: String) async throws -> String
}

public struct MockSpeechEngine: SpeechToTextEngine {
    public var transcript: Transcript?

    public init(transcript: Transcript? = nil) {
        self.transcript = transcript
    }

    public func transcribe(audio: RecordedAudio) async throws -> Transcript {
        transcript ?? Transcript(
            text: String(data: audio.data, encoding: .utf8) ?? "",
            localeIdentifier: "ja-JP",
            confidence: 1.0
        )
    }

    public func transcribeMockText(_ text: String) async throws -> String {
        text
    }
}

public struct MockAudioRecorder: AudioRecorder {
    public var audio: RecordedAudio

    public init(mockText: String) {
        self.audio = RecordedAudio(
            data: Data(mockText.utf8),
            formatDescription: "mock-text",
            durationSeconds: 0
        )
    }

    public init(audio: RecordedAudio) {
        self.audio = audio
    }

    public func recordOnce() async throws -> RecordedAudio {
        audio
    }
}

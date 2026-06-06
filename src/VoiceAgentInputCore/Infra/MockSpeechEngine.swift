import Foundation

public struct MockSpeechEngine: SpeechEngine, SpeechToTextEngine {
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

    public func transcribe(audioFile url: URL, options: TranscriptionOptions) async throws -> TranscriptionResult {
        let data = try Data(contentsOf: url)
        let transcript = transcript ?? Transcript(
            text: String(data: data, encoding: .utf8) ?? "",
            localeIdentifier: options.locale.identifier,
            confidence: 1.0
        )
        return TranscriptionResult(
            text: transcript.text,
            metadata: TranscriptionMetadata(
                engine: "MockSpeechEngine",
                localeIdentifier: transcript.localeIdentifier ?? options.locale.identifier,
                confidence: transcript.confidence,
                contextualStringCount: options.contextualStrings.phraseCount,
                recognitionMode: options.recognitionMode,
                outputDetailLevel: options.outputDetailLevel,
                transcriberProfile: options.transcriberProfile
            )
        )
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

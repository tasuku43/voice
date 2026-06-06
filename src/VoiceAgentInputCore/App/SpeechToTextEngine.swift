import Foundation

public protocol SpeechEngine {
    func transcribe(audioFile url: URL, options: TranscriptionOptions) async throws -> TranscriptionResult
}

public protocol SpeechToTextEngine {
    func transcribe(audio: RecordedAudio) async throws -> Transcript
}

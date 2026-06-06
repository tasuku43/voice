import Foundation

public protocol SpeechToTextEngine {
    func transcribe(audio: RecordedAudio) async throws -> Transcript
}

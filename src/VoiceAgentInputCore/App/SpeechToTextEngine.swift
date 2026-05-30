import Foundation

public protocol SpeechToTextEngine {
    func transcribe(audio: RecordedAudio) async throws -> Transcript
    func transcribeMockText(_ text: String) async throws -> String
}

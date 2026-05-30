import Foundation

public protocol SpeechToTextEngine {
    func transcribeMockText(_ text: String) async throws -> String
}

public struct MockSpeechEngine: SpeechToTextEngine {
    public init() {}

    public func transcribeMockText(_ text: String) async throws -> String {
        text
    }
}

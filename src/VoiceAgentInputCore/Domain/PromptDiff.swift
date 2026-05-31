import Foundation

public struct PromptDiff: Codable, Equatable, Sendable {
    public var rawText: String
    public var autoCorrectedText: String
    public var finalEditedText: String

    public init(rawText: String, autoCorrectedText: String, finalEditedText: String) {
        self.rawText = rawText
        self.autoCorrectedText = autoCorrectedText
        self.finalEditedText = finalEditedText
    }

    public var userChangedAutoCorrection: Bool {
        autoCorrectedText != finalEditedText
    }
}

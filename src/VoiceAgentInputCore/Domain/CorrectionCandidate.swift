import Foundation

public struct CorrectionCandidate: Codable, Equatable, Sendable {
    public var rawPhrase: String
    public var correctedPhrase: String
    public var confidence: Double
    public var occurrenceCount: Int
    public var reason: String
    public var suggestedScope: DictionaryScope
    public var dangerous: Bool
    public var autoApplyAllowed: Bool

    public init(
        rawPhrase: String,
        correctedPhrase: String,
        confidence: Double,
        occurrenceCount: Int = 1,
        reason: String = "User edited transcript to this phrase.",
        suggestedScope: DictionaryScope,
        dangerous: Bool = false,
        autoApplyAllowed: Bool = false
    ) {
        self.rawPhrase = rawPhrase
        self.correctedPhrase = correctedPhrase
        self.confidence = confidence
        self.occurrenceCount = occurrenceCount
        self.reason = reason
        self.suggestedScope = suggestedScope
        self.dangerous = dangerous
        self.autoApplyAllowed = autoApplyAllowed && !dangerous
    }
}

import Foundation

public struct NormalizationResult: Codable, Equatable, Sendable {
    public var rawText: String
    public var correctedText: String
    public var corrections: [AppliedCorrection]

    public init(
        rawText: String,
        correctedText: String,
        corrections: [AppliedCorrection] = []
    ) {
        self.rawText = rawText
        self.correctedText = correctedText
        self.corrections = corrections
    }
}

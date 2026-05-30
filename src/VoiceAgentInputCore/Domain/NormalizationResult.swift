import Foundation

public struct NormalizationResult: Codable, Equatable, Sendable {
    public var rawText: String
    public var correctedText: String
    public var corrections: [AppliedCorrection]
    public var candidates: [CorrectionCandidate]

    public init(
        rawText: String,
        correctedText: String,
        corrections: [AppliedCorrection] = [],
        candidates: [CorrectionCandidate] = []
    ) {
        self.rawText = rawText
        self.correctedText = correctedText
        self.corrections = corrections
        self.candidates = candidates
    }
}

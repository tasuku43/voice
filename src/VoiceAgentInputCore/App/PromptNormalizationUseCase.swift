import Foundation

public struct PromptNormalizationUseCase: Sendable {
    public var entries: [DictionaryEntry]
    public var candidateExtractor: CandidateExtractor

    public init(entries: [DictionaryEntry], candidateExtractor: CandidateExtractor = CandidateExtractor()) {
        self.entries = entries
        self.candidateExtractor = candidateExtractor
    }

    public func normalize(rawText: String) -> NormalizationResult {
        let engine = NormalizationEngine(entries: entries)
        return engine.normalize(rawText)
    }

    public func learn(rawText: String, autoCorrectedText: String, finalEditedText: String, suggestedScope: DictionaryScope = .user) -> [CorrectionCandidate] {
        let diff = PromptDiff(rawText: rawText, autoCorrectedText: autoCorrectedText, finalEditedText: finalEditedText)
        return candidateExtractor.extract(from: diff, suggestedScope: suggestedScope)
    }
}

import Foundation

public struct AgentHistoryLearningModeResult: Equatable, Sendable {
    public var scannedTextCount: Int
    public var candidates: [CorrectionCandidate]
    public var skippedExistingCandidateCount: Int

    public init(
        scannedTextCount: Int,
        candidates: [CorrectionCandidate],
        skippedExistingCandidateCount: Int = 0
    ) {
        self.scannedTextCount = scannedTextCount
        self.candidates = candidates
        self.skippedExistingCandidateCount = skippedExistingCandidateCount
    }
}

public struct AgentHistoryLearningModeUseCase: Sendable {
    public var historyProvider: any AgentHistoryTextProvider
    public var dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase

    public init(
        historyProvider: any AgentHistoryTextProvider,
        dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase = AgentHistoryDictionaryLearningUseCase()
    ) {
        self.historyProvider = historyProvider
        self.dictionaryLearningUseCase = dictionaryLearningUseCase
    }

    public func generateCandidates(
        scope: DictionaryScope = .user,
        existingEntries: [DictionaryEntry] = []
    ) throws -> AgentHistoryLearningModeResult {
        let texts = try historyProvider.historyTexts()
        let candidates = dictionaryLearningUseCase.candidates(from: texts, scope: scope)
        let freshCandidates = candidates.filter { candidate in
            !existingEntries.containsEquivalent(to: candidate)
        }
        return AgentHistoryLearningModeResult(
            scannedTextCount: texts.count,
            candidates: freshCandidates,
            skippedExistingCandidateCount: candidates.count - freshCandidates.count
        )
    }
}

private extension Array where Element == DictionaryEntry {
    func containsEquivalent(to candidate: CorrectionCandidate) -> Bool {
        contains { entry in
            entry.canonical == candidate.correctedPhrase &&
                entry.scope == candidate.suggestedScope &&
                entry.spokenForms.contains(candidate.rawPhrase)
        }
    }
}

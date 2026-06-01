import Foundation

public struct AgentHistoryLearningModeResult: Codable, Equatable, Sendable {
    public var scannedTextCount: Int
    public var sourceTextCounts: [String: Int]
    public var candidates: [CorrectionCandidate]
    public var skippedExistingCandidateCount: Int

    public init(
        scannedTextCount: Int,
        sourceTextCounts: [String: Int] = [:],
        candidates: [CorrectionCandidate],
        skippedExistingCandidateCount: Int = 0
    ) {
        self.scannedTextCount = scannedTextCount
        self.sourceTextCounts = sourceTextCounts
        self.candidates = candidates
        self.skippedExistingCandidateCount = skippedExistingCandidateCount
    }
}

public struct AgentHistoryLearningModeUseCase {
    public var learningSources: [any LearningSource]
    public var dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase

    public init(
        historyProvider: any AgentHistoryTextProvider,
        dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase = AgentHistoryDictionaryLearningUseCase()
    ) {
        self.init(
            learningSources: [historyProvider],
            dictionaryLearningUseCase: dictionaryLearningUseCase
        )
    }

    public init(
        learningSources: [any LearningSource],
        dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase = AgentHistoryDictionaryLearningUseCase()
    ) {
        self.learningSources = learningSources
        self.dictionaryLearningUseCase = dictionaryLearningUseCase
    }

    public func generateCandidates(
        scope: DictionaryScope = .user,
        existingEntries: [DictionaryEntry] = []
    ) throws -> AgentHistoryLearningModeResult {
        var sourceTextCounts: [String: Int] = [:]
        let learningTexts = try learningSources.flatMap { source -> [LearningText] in
            let texts = try source.learningTexts()
            sourceTextCounts[source.sourceKind.rawValue, default: 0] += texts.count
            return texts
        }
        let textCandidates = dictionaryLearningUseCase.candidates(
            from: learningTexts.map(\.text),
            scope: scope
        )
        let sourceCandidates = try learningSources.flatMap { source -> [CorrectionCandidate] in
            guard let candidateSource = source as? any CorrectionCandidateLearningSource else {
                return []
            }
            return try candidateSource.correctionCandidates(scope: scope)
        }
        let candidates = textCandidates + sourceCandidates
        let freshCandidates = candidates.filter { candidate in
            !existingEntries.containsEquivalent(to: candidate)
        }
        return AgentHistoryLearningModeResult(
            scannedTextCount: learningTexts.count,
            sourceTextCounts: sourceTextCounts,
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

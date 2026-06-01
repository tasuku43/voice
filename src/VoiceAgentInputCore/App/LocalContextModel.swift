import Foundation

public struct LocalContextModel: Codable, Equatable, Sendable {
    public var entries: [DictionaryEntry]
    public var sourceTextCounts: [String: Int]
    public var generatedCandidateCount: Int

    public init(
        entries: [DictionaryEntry] = [],
        sourceTextCounts: [String: Int] = [:],
        generatedCandidateCount: Int = 0
    ) {
        self.entries = entries
        self.sourceTextCounts = sourceTextCounts
        self.generatedCandidateCount = generatedCandidateCount
    }

    public var postSTTEntries: [DictionaryEntry] {
        entries
    }

    public func recognitionHints(maximumContextualStrings: Int = 100) -> SpeechRecognitionHints {
        SpeechRecognitionHintsUseCase(maximumContextualStrings: maximumContextualStrings)
            .hints(from: entries)
    }
}

public struct LocalContextModelBuildUseCase: Sendable {
    public var seedEntries: [DictionaryEntry]
    public var approvedEntries: [DictionaryEntry]

    public init(
        seedEntries: [DictionaryEntry] = SeedDictionaries.codingAgentEntries,
        approvedEntries: [DictionaryEntry] = []
    ) {
        self.seedEntries = seedEntries
        self.approvedEntries = approvedEntries
    }

    public func build(
        learningResult: AgentHistoryLearningModeResult? = nil,
        includeGeneratedCandidates: Bool = true
    ) -> LocalContextModel {
        let generatedEntries = includeGeneratedCandidates
            ? (learningResult?.candidates.map(Self.entry(from:)) ?? [])
            : []
        return LocalContextModel(
            entries: seedEntries + approvedEntries + generatedEntries,
            sourceTextCounts: learningResult?.sourceTextCounts ?? [:],
            generatedCandidateCount: learningResult?.candidates.count ?? 0
        )
    }

    private static func entry(from candidate: CorrectionCandidate) -> DictionaryEntry {
        DictionaryEntry(
            spokenForms: [candidate.rawPhrase],
            canonical: candidate.correctedPhrase,
            kind: .projectTerm,
            scope: candidate.suggestedScope,
            confidence: candidate.confidence,
            autoApply: candidate.autoApplyAllowed
        )
    }
}

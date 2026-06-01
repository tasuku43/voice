import Foundation

public struct LocalContextModel: Codable, Equatable, Sendable {
    public var entries: [DictionaryEntry]
    public var sourceTextCounts: [String: Int]
    public var generatedCandidateCount: Int
    public var lastRebuiltAt: Date?
    public var sourceKinds: [String]

    public init(
        entries: [DictionaryEntry] = [],
        sourceTextCounts: [String: Int] = [:],
        generatedCandidateCount: Int = 0,
        lastRebuiltAt: Date? = nil,
        sourceKinds: [String] = []
    ) {
        self.entries = entries
        self.sourceTextCounts = sourceTextCounts
        self.generatedCandidateCount = generatedCandidateCount
        self.lastRebuiltAt = lastRebuiltAt
        self.sourceKinds = sourceKinds
    }

    public var postSTTEntries: [DictionaryEntry] {
        entries
    }

    public func recognitionHints(maximumContextualStrings: Int = 100) -> SpeechRecognitionHints {
        SpeechRecognitionHintsUseCase(maximumContextualStrings: maximumContextualStrings)
            .hints(from: entries)
    }

    private enum CodingKeys: String, CodingKey {
        case entries
        case sourceTextCounts
        case generatedCandidateCount
        case lastRebuiltAt
        case sourceKinds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.entries = try container.decodeIfPresent([DictionaryEntry].self, forKey: .entries) ?? []
        self.sourceTextCounts = try container.decodeIfPresent([String: Int].self, forKey: .sourceTextCounts) ?? [:]
        self.generatedCandidateCount = try container.decodeIfPresent(Int.self, forKey: .generatedCandidateCount) ?? 0
        self.lastRebuiltAt = try container.decodeIfPresent(Date.self, forKey: .lastRebuiltAt)
        self.sourceKinds = try container.decodeIfPresent([String].self, forKey: .sourceKinds) ?? []
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
        includeGeneratedCandidates: Bool = true,
        rebuiltAt: Date? = nil
    ) -> LocalContextModel {
        let generatedEntries = includeGeneratedCandidates
            ? (learningResult?.candidates.map(Self.entry(from:)) ?? [])
            : []
        return LocalContextModel(
            entries: seedEntries + approvedEntries + generatedEntries,
            sourceTextCounts: learningResult?.sourceTextCounts ?? [:],
            generatedCandidateCount: learningResult?.candidates.count ?? 0,
            lastRebuiltAt: rebuiltAt,
            sourceKinds: learningResult?.sourceTextCounts.keys.sorted() ?? []
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

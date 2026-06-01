import Foundation

public struct LearningSourceSelection: Codable, Equatable, Sendable {
    public var includeAgentHistory: Bool
    public var includeRepositoryVocabulary: Bool

    public init(
        includeAgentHistory: Bool = true,
        includeRepositoryVocabulary: Bool = false
    ) {
        self.includeAgentHistory = includeAgentHistory
        self.includeRepositoryVocabulary = includeRepositoryVocabulary
    }

    public var selectedKinds: [LearningSourceKind] {
        var kinds: [LearningSourceKind] = []
        if includeAgentHistory {
            kinds.append(.agentHistory)
        }
        if includeRepositoryVocabulary {
            kinds.append(.repositoryVocabulary)
        }
        return kinds
    }

    public var isEmpty: Bool {
        selectedKinds.isEmpty
    }
}

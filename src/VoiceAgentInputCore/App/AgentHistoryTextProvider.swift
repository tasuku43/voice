import Foundation

public protocol AgentHistoryTextProvider: LearningSource {
    func historyTexts() throws -> [String]
}

public extension AgentHistoryTextProvider {
    var sourceKind: LearningSourceKind {
        .agentHistory
    }

    func learningTexts() throws -> [LearningText] {
        try historyTexts().map {
            LearningText(sourceKind: .agentHistory, text: $0)
        }
    }
}

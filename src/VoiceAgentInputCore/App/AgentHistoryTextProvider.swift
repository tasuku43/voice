import Foundation

public protocol AgentHistoryTextProvider: Sendable {
    func historyTexts() throws -> [String]
}

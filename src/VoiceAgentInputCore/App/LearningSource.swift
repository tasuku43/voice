import Foundation

public enum LearningSourceKind: String, Codable, Equatable, Sendable {
    case agentHistory
    case repositoryVocabulary
}

public struct LearningText: Codable, Equatable, Sendable {
    public var sourceKind: LearningSourceKind
    public var text: String
    public var metadata: [String: String]

    public init(
        sourceKind: LearningSourceKind,
        text: String,
        metadata: [String: String] = [:]
    ) {
        self.sourceKind = sourceKind
        self.text = text
        self.metadata = metadata
    }
}

public protocol LearningSource {
    var sourceKind: LearningSourceKind { get }
    func learningTexts() throws -> [LearningText]
}

public protocol CorrectionCandidateLearningSource: LearningSource {
    func correctionCandidates(scope: DictionaryScope) throws -> [CorrectionCandidate]
}

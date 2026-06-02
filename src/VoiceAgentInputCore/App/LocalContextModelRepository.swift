import Foundation

public protocol LocalContextModelRepository {
    func loadModel() throws -> LocalContextModel
    func saveModel(_ model: LocalContextModel) throws
}

public struct LocalContextModelDataUseCase {
    public var repository: any LocalContextModelRepository
    public var buildUseCase: LocalContextModelBuildUseCase

    public init(
        repository: any LocalContextModelRepository,
        buildUseCase: LocalContextModelBuildUseCase = LocalContextModelBuildUseCase()
    ) {
        self.repository = repository
        self.buildUseCase = buildUseCase
    }

    public func exportModel() throws -> LocalContextModel {
        try repository.loadModel()
    }

    public func importModel(_ model: LocalContextModel) throws {
        try repository.saveModel(model)
    }

    @discardableResult
    public func rebuildModel(
        learningResult: AgentHistoryLearningModeResult?,
        includeGeneratedCandidates: Bool = true,
        rebuiltAt: Date = Date()
    ) throws -> LocalContextModel {
        let model = buildUseCase.build(
            learningResult: learningResult,
            includeGeneratedCandidates: includeGeneratedCandidates,
            rebuiltAt: rebuiltAt
        )
        try repository.saveModel(model)
        return model
    }

    public func deleteLocalContextModel() throws {
        try repository.saveModel(LocalContextModel())
    }
}

public struct LocalContextModelRebuildResult: Equatable, Sendable {
    public var learningResult: AgentHistoryLearningModeResult
    public var model: LocalContextModel

    public init(learningResult: AgentHistoryLearningModeResult, model: LocalContextModel) {
        self.learningResult = learningResult
        self.model = model
    }
}

public struct LocalContextModelRebuildUseCase {
    public var learningSources: [any LearningSource]
    public var dataUseCase: LocalContextModelDataUseCase
    public var candidateGenerationUseCase: LocalContextCandidateGenerationUseCase

    public init(
        learningSources: [any LearningSource],
        dataUseCase: LocalContextModelDataUseCase,
        candidateGenerationUseCase: LocalContextCandidateGenerationUseCase = LocalContextCandidateGenerationUseCase(minimumOccurrences: 2)
    ) {
        self.learningSources = learningSources
        self.dataUseCase = dataUseCase
        self.candidateGenerationUseCase = candidateGenerationUseCase
    }

    public func rebuild(
        scope: DictionaryScope = .user,
        existingEntries: [DictionaryEntry] = [],
        rebuiltAt: Date = Date()
    ) throws -> LocalContextModelRebuildResult {
        let learningResult = try AgentHistoryLearningModeUseCase(
            learningSources: learningSources,
            contextCandidateGenerationUseCase: candidateGenerationUseCase
        ).generateCandidates(scope: scope, existingEntries: existingEntries)
        let model = try dataUseCase.rebuildModel(
            learningResult: learningResult,
            rebuiltAt: rebuiltAt
        )
        return LocalContextModelRebuildResult(
            learningResult: learningResult,
            model: model
        )
    }
}

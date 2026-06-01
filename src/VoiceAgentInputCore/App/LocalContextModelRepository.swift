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
        includeGeneratedCandidates: Bool = true
    ) throws -> LocalContextModel {
        let model = buildUseCase.build(
            learningResult: learningResult,
            includeGeneratedCandidates: includeGeneratedCandidates
        )
        try repository.saveModel(model)
        return model
    }

    public func deleteLocalContextModel() throws {
        try repository.saveModel(LocalContextModel())
    }
}

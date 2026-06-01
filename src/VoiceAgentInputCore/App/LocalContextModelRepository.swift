import Foundation

public protocol LocalContextModelRepository {
    func loadModel() throws -> LocalContextModel
    func saveModel(_ model: LocalContextModel) throws
}

public struct LocalContextModelDataUseCase {
    public var repository: any LocalContextModelRepository

    public init(repository: any LocalContextModelRepository) {
        self.repository = repository
    }

    public func exportModel() throws -> LocalContextModel {
        try repository.loadModel()
    }

    public func importModel(_ model: LocalContextModel) throws {
        try repository.saveModel(model)
    }

    public func deleteLocalContextModel() throws {
        try repository.saveModel(LocalContextModel())
    }
}

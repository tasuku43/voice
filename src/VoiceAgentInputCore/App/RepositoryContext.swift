import Foundation

public struct RepositoryContext: Equatable, Sendable {
    public var rootPath: String
    public var branchName: String?

    public init(rootPath: String, branchName: String? = nil) {
        self.rootPath = rootPath
        self.branchName = branchName
    }
}

public protocol RepositoryContextProvider {
    func currentContext(startingAt path: URL) throws -> RepositoryContext?
}

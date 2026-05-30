import Foundation

public final class MockCommandRunner: CommandRunner {
    public var outputs: [String]
    public private(set) var invocations: [(executable: String, arguments: [String])] = []

    public init(outputs: [String]) {
        self.outputs = outputs
    }

    public func run(executable: String, arguments: [String]) throws -> String {
        invocations.append((executable: executable, arguments: arguments))
        guard !outputs.isEmpty else {
            throw GitRepositoryContextError.commandFailed("missing mock output")
        }
        return outputs.removeFirst()
    }
}

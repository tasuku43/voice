import Foundation

public struct GitRepositoryContextProvider: RepositoryContextProvider {
    public var commandRunner: any CommandRunner

    public init(commandRunner: any CommandRunner = ProcessCommandRunner()) {
        self.commandRunner = commandRunner
    }

    public func currentContext(startingAt path: URL) throws -> RepositoryContext? {
        let root = try commandRunner.run(
            executable: "/usr/bin/git",
            arguments: ["-C", path.path, "rev-parse", "--show-toplevel"]
        )
        let rootPath = root.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rootPath.isEmpty else {
            return nil
        }

        let branch = try? commandRunner.run(
            executable: "/usr/bin/git",
            arguments: ["-C", rootPath, "branch", "--show-current"]
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        return RepositoryContext(
            rootPath: rootPath,
            branchName: branch?.isEmpty == false ? branch : nil
        )
    }
}

public protocol CommandRunner {
    func run(executable: String, arguments: [String]) throws -> String
}

public struct ProcessCommandRunner: CommandRunner {
    public init() {}

    public func run(executable: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if process.terminationStatus == 0 {
            return output
        }

        let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        throw GitRepositoryContextError.commandFailed(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

public enum GitRepositoryContextError: Error, Equatable {
    case commandFailed(String)
}

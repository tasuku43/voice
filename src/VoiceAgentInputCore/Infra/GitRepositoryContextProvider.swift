import Foundation

public struct GitRepositoryContextProvider: RepositoryContextProvider, RepositoryVocabularyFilePathProvider {
    public var commandRunner: any CommandRunner
    public var maximumVocabularyFiles: Int
    public var allowedVocabularyExtensions: Set<String>

    public init(
        commandRunner: any CommandRunner = ProcessCommandRunner(),
        maximumVocabularyFiles: Int = 200,
        allowedVocabularyExtensions: Set<String> = ["swift", "md", "json", "yml", "yaml", "sh", "py", "js", "ts", "tsx"]
    ) {
        self.commandRunner = commandRunner
        self.maximumVocabularyFiles = maximumVocabularyFiles
        self.allowedVocabularyExtensions = allowedVocabularyExtensions
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

    public func trackedVocabularyFilePaths(rootPath: String) throws -> [String] {
        guard maximumVocabularyFiles > 0 else {
            return []
        }
        let output = try commandRunner.run(
            executable: "/usr/bin/git",
            arguments: ["-C", rootPath, "ls-files"]
        )
        let filePaths = output
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .filter { allowedVocabularyExtensions.contains(URL(fileURLWithPath: $0).pathExtension.lowercased()) }
        return Array(filePaths.prefix(maximumVocabularyFiles))
    }
}

public protocol CommandRunner {
    func run(executable: String, arguments: [String]) throws -> String
}

public struct ProcessCommandRunner: CommandRunner {
    public init() {}

    public func run(executable: String, arguments: [String]) throws -> String {
        guard executable == "/usr/bin/git" else {
            throw GitRepositoryContextError.disallowedCommand(executable)
        }
        try Self.validateLocalReadOnlyGitArguments(arguments)

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

    private static func validateLocalReadOnlyGitArguments(_ arguments: [String]) throws {
        guard arguments.count >= 3, arguments[0] == "-C" else {
            throw GitRepositoryContextError.disallowedCommand(arguments.joined(separator: " "))
        }
        let subcommand = arguments[2]
        let allowed: Set<[String]> = [
            ["rev-parse", "--show-toplevel"],
            ["branch", "--show-current"],
            ["ls-files"]
        ]
        let trailingArguments = Array(arguments.dropFirst(2))
        guard allowed.contains(trailingArguments), subcommand != "fetch", subcommand != "pull", subcommand != "clone" else {
            throw GitRepositoryContextError.disallowedCommand(arguments.joined(separator: " "))
        }
    }
}

public enum GitRepositoryContextError: Error, Equatable {
    case commandFailed(String)
    case disallowedCommand(String)
}

import Foundation

struct AppDebugLogger: Sendable {
    let enabled: Bool
    let logFileURL: URL

    init(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        enabled = arguments.contains("--debug") || environment["VOICE_AGENT_INPUT_DEBUG"] == "1"
        logFileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("VoiceAgentInput")
            .appendingPathComponent("debug.log")
    }

    func log(_ message: String) {
        let line = "\(Self.timestamp()) \(message)\n"
        fputs(line, stderr)
        guard enabled else {
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: logFileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let handle = try FileHandle(forWritingTo: logFileURL)
                try handle.seekToEnd()
                if let data = line.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
                try handle.close()
            } else {
                try line.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            fputs("\(Self.timestamp()) failed to write debug log: \(error)\n", stderr)
        }
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}

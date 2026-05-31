import Foundation

public struct LocalAgentHistoryTextProvider: AgentHistoryTextProvider {
    public var homeDirectory: URL
    public var maximumClaudeProjectFiles: Int
    public var maximumBytesPerFile: Int
    public var allowedClaudeProjectExtensions: Set<String>

    public init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        maximumClaudeProjectFiles: Int = 40,
        maximumBytesPerFile: Int = 512_000,
        allowedClaudeProjectExtensions: Set<String> = ["jsonl", "json", "md", "txt"]
    ) {
        self.homeDirectory = homeDirectory
        self.maximumClaudeProjectFiles = maximumClaudeProjectFiles
        self.maximumBytesPerFile = maximumBytesPerFile
        self.allowedClaudeProjectExtensions = allowedClaudeProjectExtensions
    }

    public func historyTexts() throws -> [String] {
        let urls = historyFileURLs()
        return try urls.compactMap { url in
            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            let limitedData = data.prefix(maximumBytesPerFile)
            return Self.historyText(from: Data(limitedData), pathExtension: url.pathExtension)
        }
    }

    public func historyFileURLs() -> [URL] {
        var urls: [URL] = [
            homeDirectory.appendingPathComponent(".codex/history.jsonl"),
            homeDirectory.appendingPathComponent(".codex/transcription-history.jsonl"),
            homeDirectory.appendingPathComponent(".codex/session_index.jsonl")
        ]

        urls += boundedHistoryFiles(
            under: homeDirectory.appendingPathComponent(".claude/projects")
        )
        return urls
    }

    static func historyText(from data: Data, pathExtension: String) -> String? {
        guard let rawText = String(data: data, encoding: .utf8) else {
            return nil
        }
        let normalizedExtension = pathExtension.lowercased()
        guard normalizedExtension == "jsonl" || normalizedExtension == "json" else {
            return rawText
        }

        let fragments: [String]
        let parsedStructuredJSON: Bool
        if normalizedExtension == "jsonl" {
            var didParseJSONLine = false
            fragments = rawText
                .split(whereSeparator: \.isNewline)
                .flatMap { line -> [String] in
                    guard let lineData = String(line).data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: lineData) else {
                        return []
                    }
                    didParseJSONLine = true
                    return Self.userTextFragments(from: json)
                }
            parsedStructuredJSON = didParseJSONLine
        } else if let json = try? JSONSerialization.jsonObject(with: data) {
            fragments = Self.userTextFragments(from: json)
            parsedStructuredJSON = true
        } else {
            fragments = []
            parsedStructuredJSON = false
        }

        let extracted = fragments
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        if !extracted.isEmpty {
            return extracted
        }
        return parsedStructuredJSON ? nil : rawText
    }

    private static func userTextFragments(
        from value: Any,
        key: String? = nil,
        inheritedActor: HistoryActor? = nil
    ) -> [String] {
        if let text = value as? String {
            guard isTextPayloadKey(key), inheritedActor != .assistant else {
                return []
            }
            return [text]
        }

        if let array = value as? [Any] {
            return array.flatMap {
                userTextFragments(from: $0, key: key, inheritedActor: inheritedActor)
            }
        }

        guard let object = value as? [String: Any] else {
            return []
        }

        let actor = actor(in: object) ?? inheritedActor
        guard actor != .assistant else {
            return []
        }

        return object.flatMap { nestedKey, nestedValue in
            userTextFragments(from: nestedValue, key: nestedKey, inheritedActor: actor)
        }
    }

    private static func actor(in object: [String: Any]) -> HistoryActor? {
        for key in ["role", "author", "speaker"] {
            guard let value = object[key] as? String else {
                continue
            }
            let lowered = value.lowercased()
            if lowered.contains("assistant") {
                return .assistant
            }
            if lowered.contains("user") || lowered.contains("human") {
                return .user
            }
        }
        return nil
    }

    private static func isTextPayloadKey(_ key: String?) -> Bool {
        guard let key else {
            return false
        }
        return [
            "text",
            "content",
            "prompt",
            "message",
            "input",
            "request"
        ].contains(key)
    }

    private func boundedHistoryFiles(under directoryURL: URL) -> [URL] {
        guard maximumClaudeProjectFiles > 0 else {
            return []
        }
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var files: [HistoryFileCandidate] = []
        for case let url as URL in enumerator {
            guard allowedClaudeProjectExtensions.contains(url.pathExtension.lowercased()) else {
                continue
            }
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey]),
                  values.isRegularFile == true else {
                continue
            }
            files.append(HistoryFileCandidate(
                url: url,
                modificationDate: values.contentModificationDate ?? .distantPast
            ))
        }
        return files
            .sorted { lhs, rhs in
                if lhs.modificationDate != rhs.modificationDate {
                    return lhs.modificationDate > rhs.modificationDate
                }
                return lhs.url.path < rhs.url.path
            }
            .prefix(maximumClaudeProjectFiles)
            .map(\.url)
    }
}

private enum HistoryActor {
    case user
    case assistant
}

private struct HistoryFileCandidate {
    var url: URL
    var modificationDate: Date
}

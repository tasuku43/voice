import Foundation

public struct LocalAppDataStore {
    public var directoryURL: URL

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    public static func defaultDirectoryURL(appName: String = "VoiceAgentInput") throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(appName, isDirectory: true)
    }

    public func settingsRepository(fileName: String = "settings.json") throws -> JSONAppSettingsRepository {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return JSONAppSettingsRepository(fileURL: directoryURL.appendingPathComponent(fileName))
    }

    public func voiceInputHistoryRepository(fileName: String = "voice-input-history.json") throws -> JSONVoiceInputHistoryRepository {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return JSONVoiceInputHistoryRepository(fileURL: directoryURL.appendingPathComponent(fileName))
    }

    public func localContextModelRepository(fileName: String = "local-context-model.json") throws -> JSONLocalContextModelRepository {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return JSONLocalContextModelRepository(fileURL: directoryURL.appendingPathComponent(fileName))
    }
}

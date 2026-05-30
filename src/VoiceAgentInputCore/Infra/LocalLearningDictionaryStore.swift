import Foundation

public struct LocalLearningDictionaryStore {
    public var directoryURL: URL
    public var fileName: String

    public init(directoryURL: URL, fileName: String = "approved-dictionary.json") {
        self.directoryURL = directoryURL
        self.fileName = fileName
    }

    public static func defaultDirectoryURL(appName: String = "VoiceAgentInput") throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(appName, isDirectory: true)
    }

    public func repository() throws -> JSONDictionaryRepository {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return JSONDictionaryRepository(fileURL: directoryURL.appendingPathComponent(fileName))
    }

    public func settingsRepository(fileName: String = "settings.json") throws -> JSONAppSettingsRepository {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return JSONAppSettingsRepository(fileURL: directoryURL.appendingPathComponent(fileName))
    }
}

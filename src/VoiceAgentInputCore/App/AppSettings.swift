import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var repositoryPath: String?

    public init(repositoryPath: String? = nil) {
        self.repositoryPath = repositoryPath
    }
}

public protocol AppSettingsRepository {
    func loadSettings() throws -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
}

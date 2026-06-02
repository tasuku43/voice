import Foundation

public struct AppSettingsUseCase {
    public var repository: any AppSettingsRepository

    public init(repository: any AppSettingsRepository) {
        self.repository = repository
    }

    public func loadSettings() throws -> AppSettings {
        try repository.loadSettings()
    }

    @discardableResult
    public func saveRepositoryPath(_ path: String) throws -> AppSettings {
        var settings = try repository.loadSettings()
        settings.repositoryPath = path
        try repository.saveSettings(settings)
        return settings
    }

    @discardableResult
    public func saveVoiceInputHotkey(
        shortcut: KeyboardShortcut
    ) throws -> AppSettings {
        var settings = try repository.loadSettings()
        settings.voiceInputShortcut = shortcut
        try repository.saveSettings(settings)
        return settings
    }
}

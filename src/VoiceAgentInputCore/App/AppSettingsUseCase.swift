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
    public func saveRecordingSettings(
        recordingDurationSeconds: TimeInterval,
        speechLocaleIdentifier: String
    ) throws -> AppSettings {
        var settings = try repository.loadSettings()
        settings.recordingDurationSeconds = recordingDurationSeconds
        settings.speechLocaleIdentifier = speechLocaleIdentifier
        settings.recordingDurationSeconds = settings.effectiveRecordingDurationSeconds
        settings.speechLocaleIdentifier = settings.effectiveSpeechLocaleIdentifier
        try repository.saveSettings(settings)
        return settings
    }

    @discardableResult
    public func saveVoiceInputHotkey(
        shortcut: KeyboardShortcut,
        triggerMode: VoiceInputTriggerMode
    ) throws -> AppSettings {
        var settings = try repository.loadSettings()
        settings.voiceInputShortcut = shortcut
        settings.voiceInputTriggerMode = triggerMode
        try repository.saveSettings(settings)
        return settings
    }
}

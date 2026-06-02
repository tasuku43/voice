import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultSpeechLocaleIdentifier = "ja-JP"
    public static let defaultVoiceInputTriggerMode = VoiceInputTriggerMode.pressAndHold

    public var repositoryPath: String?
    public var voiceInputShortcut: KeyboardShortcut
    public var voiceInputTriggerMode: VoiceInputTriggerMode

    public init(
        repositoryPath: String? = nil,
        voiceInputShortcut: KeyboardShortcut = .defaultVoiceInput,
        voiceInputTriggerMode: VoiceInputTriggerMode = Self.defaultVoiceInputTriggerMode
    ) {
        self.repositoryPath = repositoryPath
        self.voiceInputShortcut = voiceInputShortcut
        self.voiceInputTriggerMode = voiceInputTriggerMode
    }

    public var preferredLearningScope: DictionaryScope {
        .user
    }

    private enum CodingKeys: String, CodingKey {
        case repositoryPath
        case voiceInputShortcut
        case voiceInputTriggerMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        repositoryPath = try container.decodeIfPresent(String.self, forKey: .repositoryPath)
        voiceInputShortcut = try container.decodeIfPresent(KeyboardShortcut.self, forKey: .voiceInputShortcut)
            ?? .defaultVoiceInput
        voiceInputTriggerMode = try container.decodeIfPresent(VoiceInputTriggerMode.self, forKey: .voiceInputTriggerMode)
            ?? Self.defaultVoiceInputTriggerMode
    }
}

public protocol AppSettingsRepository {
    func loadSettings() throws -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
}

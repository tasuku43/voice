import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultSpeechLocaleIdentifier = "ja-JP"

    public var repositoryPath: String?
    public var voiceInputShortcut: KeyboardShortcut

    public init(
        repositoryPath: String? = nil,
        voiceInputShortcut: KeyboardShortcut = .defaultVoiceInput
    ) {
        self.repositoryPath = repositoryPath
        self.voiceInputShortcut = voiceInputShortcut
    }

    public var preferredLearningScope: DictionaryScope {
        .user
    }

    private enum CodingKeys: String, CodingKey {
        case repositoryPath
        case voiceInputShortcut
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        repositoryPath = try container.decodeIfPresent(String.self, forKey: .repositoryPath)
        voiceInputShortcut = try container.decodeIfPresent(KeyboardShortcut.self, forKey: .voiceInputShortcut)
            ?? .defaultVoiceInput
    }
}

public protocol AppSettingsRepository {
    func loadSettings() throws -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
}

import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultRecordingDurationSeconds: TimeInterval = 4
    public static let defaultSpeechLocaleIdentifier = "ja-JP"
    public static let defaultVoiceInputTriggerMode = VoiceInputTriggerMode.pressAndHold

    public var repositoryPath: String?
    public var recordingDurationSeconds: TimeInterval
    public var speechLocaleIdentifier: String
    public var voiceInputShortcut: KeyboardShortcut
    public var voiceInputTriggerMode: VoiceInputTriggerMode

    public init(
        repositoryPath: String? = nil,
        recordingDurationSeconds: TimeInterval = Self.defaultRecordingDurationSeconds,
        speechLocaleIdentifier: String = Self.defaultSpeechLocaleIdentifier,
        voiceInputShortcut: KeyboardShortcut = .defaultVoiceInput,
        voiceInputTriggerMode: VoiceInputTriggerMode = Self.defaultVoiceInputTriggerMode
    ) {
        self.repositoryPath = repositoryPath
        self.recordingDurationSeconds = recordingDurationSeconds
        self.speechLocaleIdentifier = speechLocaleIdentifier
        self.voiceInputShortcut = voiceInputShortcut
        self.voiceInputTriggerMode = voiceInputTriggerMode
    }

    public var effectiveRecordingDurationSeconds: TimeInterval {
        min(max(recordingDurationSeconds, 1), 30)
    }

    public var effectiveSpeechLocaleIdentifier: String {
        let trimmed = speechLocaleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultSpeechLocaleIdentifier : trimmed
    }

    public var preferredLearningScope: DictionaryScope {
        .user
    }

    private enum CodingKeys: String, CodingKey {
        case repositoryPath
        case recordingDurationSeconds
        case speechLocaleIdentifier
        case voiceInputShortcut
        case voiceInputTriggerMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        repositoryPath = try container.decodeIfPresent(String.self, forKey: .repositoryPath)
        recordingDurationSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .recordingDurationSeconds)
            ?? Self.defaultRecordingDurationSeconds
        speechLocaleIdentifier = try container.decodeIfPresent(String.self, forKey: .speechLocaleIdentifier)
            ?? Self.defaultSpeechLocaleIdentifier
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

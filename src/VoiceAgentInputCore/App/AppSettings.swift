import Foundation

public enum VoiceInputMode: String, Codable, Equatable, Sendable, CaseIterable {
    case quickPaste
    case learningPreview

    public var displayName: String {
        switch self {
        case .quickPaste:
            "Quick Paste"
        case .learningPreview:
            "Learning Preview"
        }
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultRecordingDurationSeconds: TimeInterval = 4
    public static let defaultSpeechLocaleIdentifier = "ja-JP"
    public static let defaultVoiceInputMode = VoiceInputMode.quickPaste

    public var repositoryPath: String?
    public var recordingDurationSeconds: TimeInterval
    public var speechLocaleIdentifier: String
    public var voiceInputMode: VoiceInputMode
    public var learningReviewerCommandPath: String?
    public var learningReviewerCommandArguments: [String]

    public init(
        repositoryPath: String? = nil,
        recordingDurationSeconds: TimeInterval = Self.defaultRecordingDurationSeconds,
        speechLocaleIdentifier: String = Self.defaultSpeechLocaleIdentifier,
        voiceInputMode: VoiceInputMode = Self.defaultVoiceInputMode,
        learningReviewerCommandPath: String? = nil,
        learningReviewerCommandArguments: [String] = []
    ) {
        self.repositoryPath = repositoryPath
        self.recordingDurationSeconds = recordingDurationSeconds
        self.speechLocaleIdentifier = speechLocaleIdentifier
        self.voiceInputMode = voiceInputMode
        self.learningReviewerCommandPath = learningReviewerCommandPath
        self.learningReviewerCommandArguments = learningReviewerCommandArguments
    }

    public var effectiveRecordingDurationSeconds: TimeInterval {
        min(max(recordingDurationSeconds, 1), 30)
    }

    public var effectiveSpeechLocaleIdentifier: String {
        let trimmed = speechLocaleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultSpeechLocaleIdentifier : trimmed
    }

    public var preferredLearningScope: DictionaryScope {
        guard let repositoryPath, !repositoryPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .user
        }
        return .repository
    }

    private enum CodingKeys: String, CodingKey {
        case repositoryPath
        case recordingDurationSeconds
        case speechLocaleIdentifier
        case voiceInputMode
        case learningReviewerCommandPath
        case learningReviewerCommandArguments
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        repositoryPath = try container.decodeIfPresent(String.self, forKey: .repositoryPath)
        recordingDurationSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .recordingDurationSeconds)
            ?? Self.defaultRecordingDurationSeconds
        speechLocaleIdentifier = try container.decodeIfPresent(String.self, forKey: .speechLocaleIdentifier)
            ?? Self.defaultSpeechLocaleIdentifier
        voiceInputMode = try container.decodeIfPresent(VoiceInputMode.self, forKey: .voiceInputMode)
            ?? Self.defaultVoiceInputMode
        learningReviewerCommandPath = try container.decodeIfPresent(String.self, forKey: .learningReviewerCommandPath)
        learningReviewerCommandArguments = try container.decodeIfPresent([String].self, forKey: .learningReviewerCommandArguments)
            ?? []
    }
}

public protocol AppSettingsRepository {
    func loadSettings() throws -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
}

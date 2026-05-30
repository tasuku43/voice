import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultRecordingDurationSeconds: TimeInterval = 4
    public static let defaultSpeechLocaleIdentifier = "ja-JP"

    public var repositoryPath: String?
    public var recordingDurationSeconds: TimeInterval
    public var speechLocaleIdentifier: String

    public init(
        repositoryPath: String? = nil,
        recordingDurationSeconds: TimeInterval = Self.defaultRecordingDurationSeconds,
        speechLocaleIdentifier: String = Self.defaultSpeechLocaleIdentifier
    ) {
        self.repositoryPath = repositoryPath
        self.recordingDurationSeconds = recordingDurationSeconds
        self.speechLocaleIdentifier = speechLocaleIdentifier
    }

    public var effectiveRecordingDurationSeconds: TimeInterval {
        min(max(recordingDurationSeconds, 1), 30)
    }

    public var effectiveSpeechLocaleIdentifier: String {
        let trimmed = speechLocaleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultSpeechLocaleIdentifier : trimmed
    }

    private enum CodingKeys: String, CodingKey {
        case repositoryPath
        case recordingDurationSeconds
        case speechLocaleIdentifier
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        repositoryPath = try container.decodeIfPresent(String.self, forKey: .repositoryPath)
        recordingDurationSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .recordingDurationSeconds)
            ?? Self.defaultRecordingDurationSeconds
        speechLocaleIdentifier = try container.decodeIfPresent(String.self, forKey: .speechLocaleIdentifier)
            ?? Self.defaultSpeechLocaleIdentifier
    }
}

public protocol AppSettingsRepository {
    func loadSettings() throws -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
}

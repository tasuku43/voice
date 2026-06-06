import Foundation

public enum SpeechEngineError: Error, Equatable, Sendable {
    case userCancelledRecording
    case audioTooShort(durationSeconds: Double, minimumDurationSeconds: Double)
    case audioFileMissing(path: String)
    case unsupportedAudioFile(path: String, debugDescription: String)
    case speechPermissionDenied(status: SpeechRecognitionPermissionStatus)
    case speechAnalyzerUnavailable(requiredOS: String)
    case unsupportedLocale(localeIdentifier: String)
    case onDeviceAssetMissing(localeIdentifier: String, status: String)
    case emptyResult
    case cancelled
    case transcriptionFailed(userMessage: String, debugDescription: String)

    public var userFacingMessage: String {
        switch self {
        case .userCancelledRecording:
            return "Recording was cancelled."
        case let .audioTooShort(durationSeconds, minimumDurationSeconds):
            return "The recording is too short (\(Self.format(durationSeconds))s). Speak for at least \(Self.format(minimumDurationSeconds))s and try again."
        case .audioFileMissing:
            return "The audio file could not be found."
        case .unsupportedAudioFile:
            return "The audio file format is not supported by Apple Speech."
        case let .speechPermissionDenied(status):
            return "Speech recognition access is \(status.rawValue). Enable speech recognition in System Settings and try again."
        case let .speechAnalyzerUnavailable(requiredOS):
            return "SpeechAnalyzer requires \(requiredOS) or later on this Mac."
        case let .unsupportedLocale(localeIdentifier):
            return "Apple Speech does not support \(localeIdentifier) on this Mac."
        case let .onDeviceAssetMissing(localeIdentifier, _):
            return "The on-device speech asset for \(localeIdentifier) is not installed. Install the local dictation/speech asset in macOS settings and try again."
        case .emptyResult:
            return "No speech was detected in the recording."
        case .cancelled:
            return "Transcription was cancelled."
        case let .transcriptionFailed(userMessage, _):
            return userMessage
        }
    }

    public var debugDescription: String {
        switch self {
        case .userCancelledRecording:
            return "userCancelledRecording"
        case let .audioTooShort(durationSeconds, minimumDurationSeconds):
            return "audioTooShort durationSeconds=\(durationSeconds) minimumDurationSeconds=\(minimumDurationSeconds)"
        case let .audioFileMissing(path):
            return "audioFileMissing path=\(path)"
        case let .unsupportedAudioFile(path, debugDescription):
            return "unsupportedAudioFile path=\(path) debug=\(debugDescription)"
        case let .speechPermissionDenied(status):
            return "speechPermissionDenied status=\(status.rawValue)"
        case let .speechAnalyzerUnavailable(requiredOS):
            return "speechAnalyzerUnavailable requiredOS=\(requiredOS)"
        case let .unsupportedLocale(localeIdentifier):
            return "unsupportedLocale localeIdentifier=\(localeIdentifier)"
        case let .onDeviceAssetMissing(localeIdentifier, status):
            return "onDeviceAssetMissing localeIdentifier=\(localeIdentifier) status=\(status)"
        case .emptyResult:
            return "emptyResult"
        case .cancelled:
            return "cancelled"
        case let .transcriptionFailed(_, debugDescription):
            return "transcriptionFailed debug=\(debugDescription)"
        }
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

import Foundation
import Speech

public struct SFSpeechRecognitionPermissionProvider: SpeechRecognitionPermissionProvider, Sendable {
    public init() {}

    public func currentStatus() -> SpeechRecognitionPermissionStatus {
        Self.map(SFSpeechRecognizer.authorizationStatus())
    }

    public func requestAccess() async -> SpeechRecognitionPermissionStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: Self.map(status))
            }
        }
    }

    private static func map(_ status: SFSpeechRecognizerAuthorizationStatus) -> SpeechRecognitionPermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .unknown
        }
    }
}

import AVFoundation
import Foundation

public struct AVFoundationMicrophonePermissionProvider: MicrophonePermissionProvider, Sendable {
    public init() {}

    public func currentStatus() -> MicrophonePermissionStatus {
        Self.map(AVCaptureDevice.authorizationStatus(for: .audio))
    }

    public func requestAccess() async -> MicrophonePermissionStatus {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                continuation.resume(returning: Self.map(AVCaptureDevice.authorizationStatus(for: .audio)))
            }
        }
    }

    private static func map(_ status: AVAuthorizationStatus) -> MicrophonePermissionStatus {
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

import Foundation

public enum MicrophonePermissionStatus: String, Equatable, Sendable {
    case authorized
    case denied
    case notDetermined
    case restricted
    case unknown
}

public protocol MicrophonePermissionProvider {
    func currentStatus() -> MicrophonePermissionStatus
    func requestAccess() async -> MicrophonePermissionStatus
}

public struct MicrophonePermissionUseCase {
    public var provider: any MicrophonePermissionProvider

    public init(provider: any MicrophonePermissionProvider) {
        self.provider = provider
    }

    @discardableResult
    public func ensureRecordingAllowed() async throws -> MicrophonePermissionStatus {
        let status = provider.currentStatus()
        if status == .authorized {
            return status
        }

        if status == .notDetermined {
            let requestedStatus = await provider.requestAccess()
            guard requestedStatus == .authorized else {
                throw MicrophonePermissionError.recordingNotAllowed(status: requestedStatus)
            }
            return requestedStatus
        }

        throw MicrophonePermissionError.recordingNotAllowed(status: status)
    }
}

public enum MicrophonePermissionError: Error, Equatable {
    case recordingNotAllowed(status: MicrophonePermissionStatus)
}

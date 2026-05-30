import Foundation

public final class MockMicrophonePermissionProvider: MicrophonePermissionProvider {
    public var status: MicrophonePermissionStatus
    public var requestedStatus: MicrophonePermissionStatus
    public private(set) var requestAccessCallCount = 0

    public init(status: MicrophonePermissionStatus, requestedStatus: MicrophonePermissionStatus? = nil) {
        self.status = status
        self.requestedStatus = requestedStatus ?? status
    }

    public func currentStatus() -> MicrophonePermissionStatus {
        status
    }

    public func requestAccess() async -> MicrophonePermissionStatus {
        requestAccessCallCount += 1
        status = requestedStatus
        return status
    }
}

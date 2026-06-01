import Foundation

public final class MockInputMonitoringPermissionProvider: InputMonitoringPermissionProvider {
    public var status: InputMonitoringPermissionStatus
    public var requestedStatus: InputMonitoringPermissionStatus
    public private(set) var requestAccessCallCount = 0

    public init(
        status: InputMonitoringPermissionStatus,
        requestedStatus: InputMonitoringPermissionStatus? = nil
    ) {
        self.status = status
        self.requestedStatus = requestedStatus ?? status
    }

    public func currentStatus() -> InputMonitoringPermissionStatus {
        status
    }

    public func requestAccess() -> InputMonitoringPermissionStatus {
        requestAccessCallCount += 1
        status = requestedStatus
        return requestedStatus
    }
}

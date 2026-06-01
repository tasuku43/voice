import CoreGraphics
import Foundation

public struct CGEventInputMonitoringPermissionProvider: InputMonitoringPermissionProvider {
    public init() {}

    public func currentStatus() -> InputMonitoringPermissionStatus {
        CGPreflightListenEventAccess() ? .trusted : .notTrusted
    }

    public func requestAccess() -> InputMonitoringPermissionStatus {
        CGRequestListenEventAccess() ? .trusted : .notTrusted
    }
}

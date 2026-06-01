import Foundation

public enum InputMonitoringPermissionStatus: String, Equatable, Sendable {
    case trusted
    case notTrusted
}

public protocol InputMonitoringPermissionProvider {
    func currentStatus() -> InputMonitoringPermissionStatus
    func requestAccess() -> InputMonitoringPermissionStatus
}

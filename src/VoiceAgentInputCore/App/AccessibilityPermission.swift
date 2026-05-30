import Foundation

public enum AccessibilityPermissionStatus: String, Equatable, Sendable {
    case trusted
    case notTrusted
}

public protocol AccessibilityPermissionProvider {
    func currentStatus() -> AccessibilityPermissionStatus
}

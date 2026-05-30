import Foundation

public struct MockAccessibilityPermissionProvider: AccessibilityPermissionProvider {
    public var status: AccessibilityPermissionStatus

    public init(status: AccessibilityPermissionStatus) {
        self.status = status
    }

    public func currentStatus() -> AccessibilityPermissionStatus {
        status
    }
}

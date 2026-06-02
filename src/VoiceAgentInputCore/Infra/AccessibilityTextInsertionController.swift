import AppKit
import ApplicationServices
import Foundation

public struct AccessibilityTextInsertionController: TextInsertionController {
    public var pasteboardController: PasteboardTextInsertionController
    public var permissionProvider: any AccessibilityPermissionProvider
    public var pasteCommandSender: any PasteCommandSender

    public init(
        pasteboardController: PasteboardTextInsertionController = PasteboardTextInsertionController(),
        permissionProvider: any AccessibilityPermissionProvider = AXAccessibilityPermissionProvider(),
        pasteCommandSender: any PasteCommandSender = CGEventPasteCommandSender()
    ) {
        self.pasteboardController = pasteboardController
        self.permissionProvider = permissionProvider
        self.pasteCommandSender = pasteCommandSender
    }

    public func insert(_ request: TextInsertionRequest) throws {
        guard permissionProvider.currentStatus() == .trusted else {
            throw AccessibilityTextInsertionError.accessibilityPermissionRequired
        }

        try pasteboardController.insert(request)
        try pasteCommandSender.sendPasteCommand()
    }
}

public enum AccessibilityTextInsertionError: Error, Equatable {
    case accessibilityPermissionRequired
    case pasteCommandUnavailable
}

public protocol PasteCommandSender {
    func sendPasteCommand() throws
}

public final class MockPasteCommandSender: PasteCommandSender {
    public private(set) var sendCount = 0

    public init() {}

    public func sendPasteCommand() throws {
        sendCount += 1
    }
}

public struct AXAccessibilityPermissionProvider: AccessibilityPermissionProvider {
    public init() {}

    public func currentStatus() -> AccessibilityPermissionStatus {
        AXIsProcessTrusted() ? .trusted : .notTrusted
    }
}

public struct CGEventPasteCommandSender: PasteCommandSender {
    public init() {}

    public func sendPasteCommand() throws {
        guard
            let source = CGEventSource(stateID: .hidSystemState),
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        else {
            throw AccessibilityTextInsertionError.pasteCommandUnavailable
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

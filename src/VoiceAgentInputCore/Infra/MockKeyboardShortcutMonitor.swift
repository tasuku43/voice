import Foundation

public final class MockKeyboardShortcutMonitor: KeyboardShortcutMonitor {
    public private(set) var shortcut: KeyboardShortcut?
    private var onTrigger: (() -> Void)?

    public init() {}

    public func start(shortcut: KeyboardShortcut, onTrigger: @escaping () -> Void) {
        self.shortcut = shortcut
        self.onTrigger = onTrigger
    }

    public func stop() {
        shortcut = nil
        onTrigger = nil
    }

    public func trigger() {
        onTrigger?()
    }
}

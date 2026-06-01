import Foundation

public final class MockKeyboardShortcutMonitor: KeyboardShortcutMonitor {
    public private(set) var shortcut: KeyboardShortcut?
    private var onTrigger: (() -> Void)?
    private var onRelease: (() -> Void)?

    public init() {}

    public func start(shortcut: KeyboardShortcut, onTrigger: @escaping () -> Void, onRelease: (() -> Void)? = nil) {
        self.shortcut = shortcut
        self.onTrigger = onTrigger
        self.onRelease = onRelease
    }

    public func stop() {
        shortcut = nil
        onTrigger = nil
        onRelease = nil
    }

    public func trigger() {
        onTrigger?()
    }

    public func release() {
        onRelease?()
    }
}

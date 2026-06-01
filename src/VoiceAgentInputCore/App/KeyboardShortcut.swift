import Foundation

public struct KeyboardShortcut: Equatable, Sendable {
    public struct Modifiers: OptionSet, Equatable, Sendable {
        public let rawValue: Int

        public static let command = Modifiers(rawValue: 1 << 0)
        public static let option = Modifiers(rawValue: 1 << 1)
        public static let control = Modifiers(rawValue: 1 << 2)
        public static let shift = Modifiers(rawValue: 1 << 3)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public var key: String
    public var modifiers: Modifiers

    public init(key: String, modifiers: Modifiers) {
        self.key = key.lowercased()
        self.modifiers = modifiers
    }

    public static let defaultVoiceInput = KeyboardShortcut(
        key: "space",
        modifiers: [.control, .option]
    )

    public static let defaultVoiceInputHistory = KeyboardShortcut(
        key: "v",
        modifiers: [.control, .shift]
    )
}

@MainActor
public protocol KeyboardShortcutMonitor {
    func start(shortcut: KeyboardShortcut, onTrigger: @escaping () -> Void, onRelease: (() -> Void)?)
    func stop()
}

public extension KeyboardShortcutMonitor {
    func start(shortcut: KeyboardShortcut, onTrigger: @escaping () -> Void) {
        start(shortcut: shortcut, onTrigger: onTrigger, onRelease: nil)
    }
}

import Foundation

public struct KeyboardShortcut: Codable, Equatable, Sendable {
    public struct Modifiers: OptionSet, Codable, Equatable, Sendable {
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

    public var displayName: String {
        var parts: [String] = []
        if modifiers.contains(.control) {
            parts.append("Control")
        }
        if modifiers.contains(.shift) {
            parts.append("Shift")
        }
        if modifiers.contains(.command) {
            parts.append("Command")
        }
        if modifiers.contains(.option) {
            parts.append("Option")
        }
        parts.append(Self.displayName(forKey: key))
        return parts.joined(separator: "-")
    }

    public static func displayName(forKey key: String) -> String {
        switch key.lowercased() {
        case "space":
            "Space"
        default:
            key.uppercased()
        }
    }
}

public enum VoiceInputTriggerMode: String, Codable, Equatable, Sendable, CaseIterable {
    case pressAndHold
    case toggleRecording

    public var displayName: String {
        switch self {
        case .pressAndHold:
            "Press and Hold"
        case .toggleRecording:
            "Toggle Recording"
        }
    }
}

public enum VoiceInputHotkeyEvent: Equatable, Sendable {
    case pressed
    case released
}

public enum VoiceInputHotkeyAction: Equatable, Sendable {
    case startRecording
    case stopRecording
    case none
}

public struct VoiceInputHotkeyUseCase: Sendable {
    public init() {}

    public func action(
        triggerMode: VoiceInputTriggerMode,
        event: VoiceInputHotkeyEvent,
        isRecording: Bool
    ) -> VoiceInputHotkeyAction {
        switch (triggerMode, event, isRecording) {
        case (.pressAndHold, .pressed, false):
            .startRecording
        case (.pressAndHold, .released, true):
            .stopRecording
        case (.toggleRecording, .pressed, false):
            .startRecording
        case (.toggleRecording, .pressed, true):
            .stopRecording
        default:
            .none
        }
    }
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

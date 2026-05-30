import AppKit
import VoiceAgentInputCore

@main
@MainActor
final class VoiceAgentInputApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var previewWindowController: PreviewWindowController?
    private let hotkeyMonitor = AppKitKeyboardShortcutMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installMenuBarItem()
        hotkeyMonitor.start(shortcut: .defaultVoiceInput) { [weak self] in
            Task { @MainActor in
                self?.showMockPreview()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyMonitor.stop()
    }

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "Voice"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Mock Preview", action: #selector(showMockPreview), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Hotkey: Command-Shift-Space", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
    }

    @objc private func showMockPreview() {
        let preview = PromptPreviewUseCase(entries: SeedDictionaries.codingAgentEntries).preview(
            rawTranscript: "くらのコードでタイプスクリプトエラーを直して"
        )

        let controller = PreviewWindowController(preview: preview)
        previewWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}

@MainActor
private final class AppKitKeyboardShortcutMonitor: KeyboardShortcutMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func start(shortcut: KeyboardShortcut, onTrigger: @escaping () -> Void) {
        stop()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if Self.matches(event: event, shortcut: shortcut) {
                Task { @MainActor in
                    onTrigger()
                }
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if Self.matches(event: event, shortcut: shortcut) {
                onTrigger()
                return nil
            }
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    private static func matches(event: NSEvent, shortcut: KeyboardShortcut) -> Bool {
        normalizedKey(from: event) == shortcut.key
            && modifierSet(from: event.modifierFlags) == shortcut.modifiers
    }

    private static func normalizedKey(from event: NSEvent) -> String {
        if event.keyCode == 49 {
            return "space"
        }
        return (event.charactersIgnoringModifiers ?? "").lowercased()
    }

    private static func modifierSet(from flags: NSEvent.ModifierFlags) -> KeyboardShortcut.Modifiers {
        var modifiers: KeyboardShortcut.Modifiers = []
        if flags.contains(.command) {
            modifiers.insert(.command)
        }
        if flags.contains(.option) {
            modifiers.insert(.option)
        }
        if flags.contains(.control) {
            modifiers.insert(.control)
        }
        if flags.contains(.shift) {
            modifiers.insert(.shift)
        }
        return modifiers
    }
}

@MainActor
private final class PreviewWindowController: NSWindowController {
    private let preview: PromptPreview
    private let previewUseCase = PromptPreviewUseCase(entries: SeedDictionaries.codingAgentEntries)
    private let correctedTextView = NSTextView()

    init(preview: PromptPreview) {
        self.preview = preview

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 420),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Voice Agent Input"
        window.center()

        super.init(window: window)
        window.contentView = buildContentView()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func buildContentView() -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 12
        container.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let rawLabel = NSTextField(labelWithString: "Raw transcript")
        let rawText = textBox(preview.rawTranscript, editable: false)
        let correctedLabel = NSTextField(labelWithString: "Corrected prompt")
        let correctedScrollView = textBox(preview.correctedPrompt, editable: true)

        if let textView = correctedScrollView.documentView as? NSTextView {
            correctedTextView.string = textView.string
            correctedScrollView.documentView = correctedTextView
            correctedTextView.isEditable = true
            correctedTextView.font = NSFont.systemFont(ofSize: 14)
        }

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8
        buttonRow.addArrangedSubview(NSView())

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        let confirmButton = NSButton(title: "Copy to Pasteboard", target: self, action: #selector(confirm))
        confirmButton.keyEquivalent = "\r"
        buttonRow.addArrangedSubview(cancelButton)
        buttonRow.addArrangedSubview(confirmButton)

        container.addArrangedSubview(rawLabel)
        container.addArrangedSubview(rawText)
        container.addArrangedSubview(correctedLabel)
        container.addArrangedSubview(correctedScrollView)
        container.addArrangedSubview(buttonRow)

        rawText.heightAnchor.constraint(equalToConstant: 90).isActive = true
        correctedScrollView.heightAnchor.constraint(equalToConstant: 170).isActive = true

        return container
    }

    private func textBox(_ string: String, editable: Bool) -> NSScrollView {
        let textView = NSTextView()
        textView.string = string
        textView.isEditable = editable
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.isRichText = false

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        scrollView.borderType = .bezelBorder
        return scrollView
    }

    @objc private func confirm() {
        let confirmed = previewUseCase.confirm(
            preview: preview,
            finalEditedPrompt: correctedTextView.string
        )
        let insertion = PromptInsertionUseCase(
            insertionController: PasteboardTextInsertionController()
        )

        do {
            try insertion.insert(confirmed, explicitConfirmation: true)
            try approveCandidatesIfRequested(confirmed.candidates)
            close()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    private func approveCandidatesIfRequested(_ candidates: [CorrectionCandidate]) throws {
        guard !candidates.isEmpty else {
            return
        }

        let alert = NSAlert()
        alert.messageText = "Approve dictionary candidates?"
        alert.informativeText = candidates.prefix(5)
            .map { "\($0.rawPhrase) -> \($0.correctedPhrase)" }
            .joined(separator: "\n")
        alert.addButton(withTitle: "Approve")
        alert.addButton(withTitle: "Skip")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        let repository = try store.repository()
        _ = try DictionaryLearningUseCase(repository: repository).approveCandidates(candidates)
    }

    @objc private func cancel() {
        close()
    }
}

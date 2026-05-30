import AppKit
import VoiceAgentInputCore

@main
@MainActor
final class VoiceAgentInputApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var recordMenuItem: NSMenuItem?
    private var previewWindowController: PreviewWindowController?
    private let hotkeyMonitor = AppKitKeyboardShortcutMonitor()
    private var isRecording = false {
        didSet {
            updateRecordingState()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installMenuBarItem()
        hotkeyMonitor.start(shortcut: .defaultVoiceInput) { [weak self] in
            Task { @MainActor in
                self?.recordVoiceInput()
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
        let recordItem = NSMenuItem(title: "Record Voice Input", action: #selector(recordVoiceInput), keyEquivalent: "r")
        menu.addItem(recordItem)
        menu.addItem(NSMenuItem(title: "Mock Preview", action: #selector(showMockPreview), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Hotkey: Command-Shift-Space", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Set Repository Folder...", action: #selector(setRepositoryFolder), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
        recordMenuItem = recordItem
        updateRecordingState()
    }

    @objc private func showMockPreview() {
        presentPreview(rawTranscript: "くらのコードでタイプスクリプトエラーを直して")
    }

    @objc private func recordVoiceInput() {
        guard !isRecording else {
            return
        }
        isRecording = true

        let entries: [DictionaryEntry]
        do {
            entries = try loadDictionaryEntries()
        } catch {
            isRecording = false
            presentError(error)
            return
        }

        Task {
            do {
                let previewUseCase = PromptPreviewUseCase(entries: entries)
                try await SpeechRecognitionPermissionUseCase(
                    provider: SFSpeechRecognitionPermissionProvider()
                ).ensureTranscriptionAllowed()
                let voiceFlow = VoiceInputFlowUseCase(
                    audioRecorder: AVFoundationAudioRecorder(durationSeconds: 4),
                    microphonePermissionProvider: AVFoundationMicrophonePermissionProvider(),
                    speechEngine: AppleSpeechEngine(localeIdentifier: "ja-JP", requiresOnDeviceRecognition: true),
                    previewUseCase: previewUseCase
                )
                let preview = try await voiceFlow.recordTranscribeAndPreview()
                await MainActor.run {
                    self.isRecording = false
                    self.openPreview(preview: preview, previewUseCase: previewUseCase)
                }
            } catch {
                await MainActor.run {
                    self.isRecording = false
                    self.presentError(error)
                }
            }
        }
    }

    private func updateRecordingState() {
        statusItem?.button?.title = isRecording ? "Voice..." : "Voice"
        recordMenuItem?.title = isRecording ? "Recording..." : "Record Voice Input"
        recordMenuItem?.isEnabled = !isRecording
    }

    private func presentPreview(rawTranscript: String) {
        let entries: [DictionaryEntry]
        do {
            entries = try loadDictionaryEntries()
        } catch {
            presentError(error)
            return
        }
        let previewUseCase = PromptPreviewUseCase(entries: entries)
        let preview = previewUseCase.preview(rawTranscript: rawTranscript)
        openPreview(preview: preview, previewUseCase: previewUseCase)
    }

    private func openPreview(preview: PromptPreview, previewUseCase: PromptPreviewUseCase) {
        let controller = PreviewWindowController(preview: preview, previewUseCase: previewUseCase)
        previewWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func loadDictionaryEntries() throws -> [DictionaryEntry] {
        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        let repository = try store.repository()
        return try DictionaryEntryLoadingUseCase(
            repository: repository,
            contextualEntries: loadRepositoryVocabularyEntries()
        ).loadEntries()
    }

    private func loadRepositoryVocabularyEntries() -> [DictionaryEntry] {
        let startURL = configuredRepositoryURL() ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        guard let context = try? GitRepositoryContextProvider().currentContext(startingAt: startURL) else {
            return []
        }
        return RepositoryVocabularyUseCase().entries(from: context)
    }

    private func configuredRepositoryURL() -> URL? {
        guard
            let settings = try? settingsRepository().loadSettings(),
            let repositoryPath = settings.repositoryPath,
            !repositoryPath.isEmpty
        else {
            return nil
        }
        return URL(fileURLWithPath: repositoryPath)
    }

    private func settingsRepository() throws -> JSONAppSettingsRepository {
        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        return try store.settingsRepository()
    }

    @objc private func setRepositoryFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a Git repository folder for repository-scoped vocabulary."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let repository = try settingsRepository()
            var settings = try repository.loadSettings()
            settings.repositoryPath = url.path
            try repository.saveSettings(settings)
        } catch {
            presentError(error)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Voice input could not start"
        alert.informativeText = userFacingMessage(for: error)
        alert.runModal()
    }

    private func userFacingMessage(for error: Error) -> String {
        if let flowError = error as? VoiceInputFlowError {
            switch flowError {
            case .audioRecorderUnavailable:
                return "The audio recorder is not available."
            case let .microphonePermissionDenied(status):
                return "Microphone access is \(status.rawValue). Enable microphone access in System Settings and try again."
            }
        }

        if let speechError = error as? SpeechRecognitionPermissionError {
            switch speechError {
            case let .transcriptionNotAllowed(status):
                return "Speech recognition access is \(status.rawValue). Enable speech recognition in System Settings and try again."
            }
        }

        if let speechError = error as? AppleSpeechEngineError {
            switch speechError {
            case let .recognizerUnavailable(localeIdentifier):
                return "Apple Speech is not available for \(localeIdentifier) right now. Check the macOS speech recognition setting and try again."
            }
        }

        return String(describing: error)
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
    private let previewUseCase: PromptPreviewUseCase
    private let correctedTextView = NSTextView()

    init(preview: PromptPreview, previewUseCase: PromptPreviewUseCase) {
        self.preview = preview
        self.previewUseCase = previewUseCase

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
        let confirmButton = NSButton(title: "Paste", target: self, action: #selector(confirm))
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
        let insertion = PromptInsertionUseCase(insertionController: AccessibilityTextInsertionController())

        do {
            try insertion.insert(confirmed, explicitConfirmation: true)
            try approveCandidatesIfRequested(confirmed.candidates)
            close()
        } catch AccessibilityTextInsertionError.accessibilityPermissionRequired {
            do {
                try PromptInsertionUseCase(
                    insertionController: PasteboardTextInsertionController()
                ).insert(confirmed, explicitConfirmation: true)
                showAccessibilityFallbackAlert()
                try approveCandidatesIfRequested(confirmed.candidates)
                close()
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    private func showAccessibilityFallbackAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Prompt copied"
        alert.informativeText = "Enable Accessibility access for Voice Agent Input in System Settings to paste automatically. For now, press Command-V in the target app."
        alert.runModal()
    }

    private func approveCandidatesIfRequested(_ candidates: [CorrectionCandidate]) throws {
        guard !candidates.isEmpty else {
            return
        }

        let limitedCandidates = Array(candidates.prefix(8))
        let alert = NSAlert()
        alert.messageText = "Approve dictionary candidates?"
        alert.informativeText = "Selected candidates will be reused in later prompts."
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        let checkboxes = limitedCandidates.map { candidate in
            let checkbox = NSButton(
                checkboxWithTitle: "\(candidate.rawPhrase) -> \(candidate.correctedPhrase)",
                target: nil,
                action: nil
            )
            checkbox.state = candidate.dangerous ? .off : .on
            checkbox.toolTip = candidate.dangerous ? "Dangerous command candidates are not selected by default." : nil
            stack.addArrangedSubview(checkbox)
            return checkbox
        }
        alert.accessoryView = stack
        alert.addButton(withTitle: "Save Selected")
        alert.addButton(withTitle: "Skip")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let selectedIndexes = Set(checkboxes.enumerated().compactMap { index, checkbox in
            checkbox.state == .on ? index : nil
        })
        let reviewedCandidates = CandidateApprovalUseCase().approveCandidates(
            limitedCandidates,
            selectedIndexes: selectedIndexes
        )
        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        let repository = try store.repository()
        _ = try DictionaryLearningUseCase(repository: repository).approveCandidates(reviewedCandidates)
    }

    @objc private func cancel() {
        close()
    }
}

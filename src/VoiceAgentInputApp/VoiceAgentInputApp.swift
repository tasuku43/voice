import AppKit
import UniformTypeIdentifiers
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
        menu.addItem(NSMenuItem(title: "Recording Settings...", action: #selector(showRecordingSettings), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Permission Status...", action: #selector(showPermissionStatus), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Privacy Settings...", action: #selector(openPrivacySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Set Repository Folder...", action: #selector(setRepositoryFolder), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Export Local Dictionary...", action: #selector(exportLocalDictionary), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Import Local Dictionary...", action: #selector(importLocalDictionary), keyEquivalent: "i"))
        menu.addItem(NSMenuItem(title: "Open Local Data Folder...", action: #selector(openLocalDataFolder), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Delete Local Dictionary...", action: #selector(deleteLocalDictionary), keyEquivalent: "d"))
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
        let settings: AppSettings
        do {
            settings = try loadSettings()
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
                let voiceInputPipeline = VoiceInputPipeline(
                    audioRecorder: AVFoundationAudioRecorder(durationSeconds: settings.effectiveRecordingDurationSeconds),
                    microphonePermissionProvider: AVFoundationMicrophonePermissionProvider(),
                    speechEngine: AppleSpeechEngine(
                        localeIdentifier: settings.effectiveSpeechLocaleIdentifier,
                        requiresOnDeviceRecognition: true
                    ),
                    normalizationContext: NormalizationContext(entries: entries)
                )
                let result = try await voiceInputPipeline.run()
                await MainActor.run {
                    self.isRecording = false
                    self.openPreview(preview: result.preview, previewUseCase: previewUseCase)
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
        try dictionaryContextLoader().loadEntries(startingAt: repositoryVocabularyStartURL())
    }

    private func loadSettings() throws -> AppSettings {
        try settingsUseCase().loadSettings()
    }

    private func dictionaryContextLoader() throws -> DictionaryContextLoadingUseCase {
        let provider = GitRepositoryContextProvider()
        return DictionaryContextLoadingUseCase(
            repository: try approvedDictionaryRepository(),
            repositoryContextProvider: provider,
            repositoryVocabularyFilePathProvider: provider
        )
    }

    private func repositoryVocabularyStartURL() -> URL {
        configuredRepositoryURL() ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    private func configuredRepositoryURL() -> URL? {
        guard
            let settings = try? loadSettings(),
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

    private func settingsUseCase() throws -> AppSettingsUseCase {
        try AppSettingsUseCase(repository: settingsRepository())
    }

    private func approvedDictionaryRepository() throws -> JSONDictionaryRepository {
        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        return try store.repository()
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
            try settingsUseCase().saveRepositoryPath(url.path)
        } catch {
            presentError(error)
        }
    }

    @objc private func showRecordingSettings() {
        do {
            let settingsUseCase = try settingsUseCase()
            let settings = try settingsUseCase.loadSettings()

            let durationField = NSTextField(
                string: String(format: "%.0f", settings.effectiveRecordingDurationSeconds)
            )
            let localeField = NSTextField(string: settings.effectiveSpeechLocaleIdentifier)
            let stack = NSStackView()
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 8
            stack.addArrangedSubview(labelledControl(label: "Recording seconds", control: durationField))
            stack.addArrangedSubview(labelledControl(label: "Speech locale", control: localeField))

            let alert = NSAlert()
            alert.messageText = "Recording settings"
            alert.informativeText = "These settings stay on this Mac and are used for the next recording."
            alert.accessoryView = stack
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Cancel")

            guard alert.runModal() == .alertFirstButtonReturn else {
                return
            }

            try settingsUseCase.saveRecordingSettings(
                recordingDurationSeconds: Double(durationField.stringValue)
                    ?? settings.effectiveRecordingDurationSeconds,
                speechLocaleIdentifier: localeField.stringValue
            )
        } catch {
            presentError(error)
        }
    }

    @objc private func showPermissionStatus() {
        let status = PermissionStatusUseCase(
            microphonePermissionProvider: AVFoundationMicrophonePermissionProvider(),
            speechRecognitionPermissionProvider: SFSpeechRecognitionPermissionProvider(),
            accessibilityPermissionProvider: AXAccessibilityPermissionProvider()
        ).currentStatus()

        let alert = NSAlert()
        alert.messageText = "Permission status"
        alert.informativeText = """
        Microphone: \(status.microphone.rawValue)
        Speech recognition: \(status.speechRecognition.rawValue)
        Accessibility paste: \(status.accessibility.rawValue)
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func labelledControl(label: String, control: NSControl) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        let labelField = NSTextField(labelWithString: label)
        labelField.frame.size.width = 130
        control.frame.size.width = 180

        row.addArrangedSubview(labelField)
        row.addArrangedSubview(control)
        return row
    }

    @objc private func exportLocalDictionary() {
        do {
            let entries = try LocalLearningDataUseCase(
                repository: approvedDictionaryRepository()
            ).exportApprovedEntries()

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "voice-agent-input-dictionary.json"
            panel.message = "Export approved local dictionary entries."

            guard panel.runModal() == .OK, let url = panel.url else {
                return
            }

            try LocalLearningDataDocumentCodec()
                .encode(entries)
                .write(to: url, options: [.atomic])
        } catch {
            presentError(error)
        }
    }

    @objc private func importLocalDictionary() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        panel.message = "Import approved local dictionary entries from JSON."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let entries = try LocalLearningDataDocumentCodec()
                .decode(try Data(contentsOf: url))
            try LocalLearningDataUseCase(
                repository: approvedDictionaryRepository()
            ).importApprovedEntries(entries, merge: true)
        } catch {
            presentError(error)
        }
    }

    @objc private func openLocalDataFolder() {
        do {
            let url = try LocalLearningDictionaryStore.defaultDirectoryURL()
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            NSWorkspace.shared.open(url)
        } catch {
            presentError(error)
        }
    }

    @objc private func deleteLocalDictionary() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Delete local dictionary?"
        alert.informativeText = "This removes approved local learning entries stored on this Mac. Repository context and bundled seed terms are not deleted."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        do {
            try LocalLearningDataUseCase(
                repository: approvedDictionaryRepository()
            ).deleteAllLocalLearningData()
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

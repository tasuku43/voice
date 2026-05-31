import AppKit
import UniformTypeIdentifiers
import VoiceAgentInputCore

@MainActor
final class VoiceAgentInputApp: NSObject, NSApplicationDelegate {
    private static let interactiveLearningReviewerTimeoutSeconds: TimeInterval = 0.5

    private let debugLogger = AppDebugLogger()
    private var statusItem: NSStatusItem?
    private var recordMenuItem: NSMenuItem?
    private var launchRecordButton: NSButton?
    private var launchWindowController: NSWindowController?
    private var debugWindowController: NSWindowController?
    private var previewWindowController: PreviewWindowController?
    private var recordingFeedbackWindowController: RecordingFeedbackWindowController?
    private var activeAudioRecorder: AVFoundationAudioRecorder?
    private var inputLevelTimer: Timer?
    private var hasDetectedVoiceInput = false
    private let hotkeyMonitor = AppKitKeyboardShortcutMonitor()
    private var isRecording = false {
        didSet {
            updateRecordingState()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        debugLogger.log("applicationDidFinishLaunching started")
        NSApp.setActivationPolicy(.regular)
        installMenuBarItem()
        showLaunchWindow()
        showDebugWindowIfNeeded()
        hotkeyMonitor.start(shortcut: .defaultVoiceInput) { [weak self] in
            Task { @MainActor in
                self?.recordVoiceInput()
            }
        }
        debugLogger.log("applicationDidFinishLaunching finished")
    }

    func applicationWillTerminate(_ notification: Notification) {
        debugLogger.log("applicationWillTerminate")
        hotkeyMonitor.stop()
    }

    private func installMenuBarItem() {
        debugLogger.log("installMenuBarItem started")
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
        menu.addItem(NSMenuItem(title: "Learning Settings...", action: #selector(showLearningSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Learn From Agent History...", action: #selector(learnFromAgentHistory), keyEquivalent: "l"))
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
        debugLogger.log("installMenuBarItem finished; button=\(item.button == nil ? "nil" : "present")")
    }

    private func showLaunchWindow() {
        debugLogger.log("showLaunchWindow started")
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Voice Agent Input"
        window.center()

        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 12
        container.alignment = .centerX
        container.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        let title = NSTextField(labelWithString: "Voice Agent Input")
        title.font = NSFont.boldSystemFont(ofSize: 18)
        let status = NSTextField(labelWithString: "Ready")

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.alignment = .centerY
        buttons.addArrangedSubview(NSButton(title: "Mock Preview", target: self, action: #selector(showMockPreview)))
        let recordButton = NSButton(title: "Record", target: self, action: #selector(recordVoiceInput))
        launchRecordButton = recordButton
        buttons.addArrangedSubview(recordButton)

        container.addArrangedSubview(title)
        container.addArrangedSubview(status)
        container.addArrangedSubview(buttons)

        window.contentView = container
        let controller = NSWindowController(window: window)
        launchWindowController = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        debugLogger.log("showLaunchWindow finished; visible=\(window.isVisible)")
    }

    private func showDebugWindowIfNeeded() {
        guard debugLogger.enabled else {
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 220),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Voice Agent Input Debug"
        window.center()

        let textView = NSTextView()
        textView.isEditable = false
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.string = """
        Voice Agent Input debug mode is active.

        Log file:
        \(debugLogger.logFileURL.path)

        Try:
        open -n .build/VoiceAgentInput.app --args --debug
        tail -f "\(debugLogger.logFileURL.path)"
        """

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        window.contentView = scrollView

        let controller = NSWindowController(window: window)
        debugWindowController = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        debugLogger.log("showDebugWindowIfNeeded finished; visible=\(window.isVisible)")
    }

    @objc private func showMockPreview() {
        debugLogger.log("showMockPreview")
        presentPreview(rawTranscript: "くらのコードでタイプスクリプトエラーを直して")
    }

    @objc private func recordVoiceInput() {
        debugLogger.log("recordVoiceInput requested")
        if isRecording {
            debugLogger.log("recordVoiceInput requested while active; stopping recording")
            activeAudioRecorder?.stopRecording()
            return
        }
        isRecording = true

        let entries: [DictionaryEntry]
        let settings: AppSettings
        do {
            settings = try loadSettings()
            entries = try loadDictionaryEntries()
            debugLogger.log("recordVoiceInput loaded settings and \(entries.count) dictionary entries")
        } catch {
            isRecording = false
            debugLogger.log("recordVoiceInput setup failed: \(error)")
            presentError(error)
            return
        }

        Task {
            do {
                let previewUseCase = PromptPreviewUseCase(entries: entries)
                try await SpeechRecognitionPermissionUseCase(
                    provider: SFSpeechRecognitionPermissionProvider()
                ).ensureTranscriptionAllowed()
                let audioRecorder = AVFoundationAudioRecorder()
                await MainActor.run {
                    self.activeAudioRecorder = audioRecorder
                    self.hasDetectedVoiceInput = false
                    self.showRecordingFeedback()
                    self.startInputLevelMonitoring()
                    self.debugLogger.log("recordVoiceInput recording started; waiting for user stop")
                }
                let speechEngine = AppleSpeechEngine(
                    localeIdentifier: settings.effectiveSpeechLocaleIdentifier,
                    requiresOnDeviceRecognition: true,
                    recognitionSnapshotHandler: { [debugLogger] snapshot, isFinal in
                        debugLogger.log("speech snapshot final=\(isFinal) text=\(snapshot)")
                    }
                )
                let voiceInputPipeline = VoiceInputPipeline(
                    audioRecorder: audioRecorder,
                    microphonePermissionProvider: AVFoundationMicrophonePermissionProvider(),
                    speechEngine: speechEngine,
                    refiner: JapanesePunctuationPromptRefiner(),
                    normalizationContext: NormalizationContext(entries: entries)
                )
                let result = try await voiceInputPipeline.run()
                await MainActor.run {
                    self.stopInputLevelMonitoring()
                    self.closeRecordingFeedback()
                    self.activeAudioRecorder = nil
                    self.isRecording = false
                    self.debugLogger.log("recordVoiceInput completed; opening preview")
                    self.openPreview(preview: result.preview, previewUseCase: previewUseCase)
                }
            } catch {
                await MainActor.run {
                    self.stopInputLevelMonitoring()
                    self.closeRecordingFeedback()
                    self.activeAudioRecorder = nil
                    self.isRecording = false
                    self.debugLogger.log("recordVoiceInput failed: \(error)")
                    self.presentError(error)
                }
            }
        }
    }

    private func updateRecordingState() {
        statusItem?.button?.title = isRecording ? "Voice..." : "Voice"
        recordMenuItem?.title = isRecording ? "Stop Voice Input" : "Record Voice Input"
        recordMenuItem?.isEnabled = true
        launchRecordButton?.title = isRecording ? "Stop" : "Record"
    }

    private func showRecordingFeedback() {
        let controller = RecordingFeedbackWindowController { [weak self] in
            Task { @MainActor in
                self?.recordVoiceInput()
            }
        }
        recordingFeedbackWindowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        controller.update(level: nil, hasDetectedVoice: false)
    }

    private func closeRecordingFeedback() {
        recordingFeedbackWindowController?.close()
        recordingFeedbackWindowController = nil
    }

    private func startInputLevelMonitoring() {
        stopInputLevelMonitoring()
        inputLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateInputLevelFeedback()
            }
        }
    }

    private func stopInputLevelMonitoring() {
        inputLevelTimer?.invalidate()
        inputLevelTimer = nil
    }

    private func updateInputLevelFeedback() {
        let level = activeAudioRecorder?.currentInputLevel()
        if let level, level > 0.08, !hasDetectedVoiceInput {
            hasDetectedVoiceInput = true
            debugLogger.log("recordVoiceInput detected microphone signal level=\(level)")
        }
        recordingFeedbackWindowController?.update(
            level: level,
            hasDetectedVoice: hasDetectedVoiceInput
        )
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
        debugLogger.log("openPreview rawLength=\(preview.rawTranscript.count) correctedLength=\(preview.correctedPrompt.count)")
        let controller = PreviewWindowController(
            preview: preview,
            previewUseCase: previewUseCase,
            editLearningUseCase: PromptEditLearningUseCase(
                previewUseCase: previewUseCase,
                candidateReviewer: learningCandidateReviewer()
            )
        )
        previewWindowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func learningCandidateReviewer() -> any LearningCandidateReviewer {
        guard
            let settings = try? loadSettings(),
            let path = settings.learningReviewerCommandPath?.trimmingCharacters(in: .whitespacesAndNewlines),
            !path.isEmpty
        else {
            return NoOpLearningCandidateReviewer()
        }
        debugLogger.log("learning reviewer command configured path=\(path) arguments=\(settings.learningReviewerCommandArguments)")
        return LocalCommandLearningCandidateReviewer(
            executableURL: URL(fileURLWithPath: path),
            arguments: settings.learningReviewerCommandArguments,
            timeoutSeconds: Self.interactiveLearningReviewerTimeoutSeconds
        )
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

    @objc private func showLearningSettings() {
        do {
            let settingsUseCase = try settingsUseCase()
            let settings = try settingsUseCase.loadSettings()
            let reviewerCommandField = NSTextField(string: settings.learningReviewerCommandPath ?? "")
            let reviewerArgumentsField = NSTextField(string: settings.learningReviewerCommandArguments.joined(separator: "\n"))
            let stack = NSStackView()
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 8
            stack.addArrangedSubview(labelledControl(label: "Reviewer command", control: reviewerCommandField))
            stack.addArrangedSubview(labelledControl(label: "Arguments", control: reviewerArgumentsField))

            let alert = NSAlert()
            alert.messageText = "Learning settings"
            alert.informativeText = "Optional local command used only after preview confirmation to review dictionary candidates. Put one argument per line. Leave command blank to keep learning fully rule-based."
            alert.accessoryView = stack
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Disable")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                try settingsUseCase.saveLearningReviewerCommand(
                    path: reviewerCommandField.stringValue,
                    arguments: reviewerArgumentsField.stringValue
                        .components(separatedBy: .newlines)
                )
            } else if response == .alertSecondButtonReturn {
                try settingsUseCase.saveLearningReviewerCommand(path: nil)
            }
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

    @objc private func learnFromAgentHistory() {
        do {
            let historyProvider = LocalAgentHistoryTextProvider()
            let existingEntries = try loadDictionaryEntries()
            let learningScope = try loadSettings().preferredLearningScope
            let result = try AgentHistoryLearningModeUseCase(
                historyProvider: historyProvider,
                dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
            ).generateCandidates(scope: learningScope, existingEntries: existingEntries)
            debugLogger.log("learnFromAgentHistory scanned \(historyProvider.historyFileURLs().count) local files, loaded \(result.scannedTextCount) texts, skipped \(result.skippedExistingCandidateCount) existing candidates, scope=\(learningScope.rawValue)")
            guard !result.candidates.isEmpty else {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = "No dictionary candidates found"
                alert.informativeText = "No new repeated developer terms were found in the bounded local Codex/Claude history scan."
                alert.runModal()
                return
            }

            try CandidateApprovalDialogController()
                .approveCandidatesIfRequested(result.candidates, maximumVisibleCandidates: 24)
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
            case .noSpeechDetected:
                return """
                No speech was detected in the recording.

                Try again while speaking during the full recording window, or open Recording Settings and increase the recording seconds. Also check that macOS is using the expected microphone input.
                """
            case let .transcriptionFailed(description):
                return "Apple Speech could not transcribe the recording: \(description)"
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

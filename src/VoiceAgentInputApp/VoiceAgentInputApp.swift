import AppKit
import ApplicationServices
import Carbon
import CoreGraphics
import UniformTypeIdentifiers
import VoiceAgentInputCore

@MainActor
final class VoiceAgentInputApp: NSObject, NSApplicationDelegate {
    private static let supportedVoiceInputHotkeyKeys = [
        "space",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
    ]

    private let debugLogger = AppDebugLogger()
    private var statusItem: NSStatusItem?
    private var recordMenuItem: NSMenuItem?
    private var hotkeyMenuItem: NSMenuItem?
    private var launchRecordButton: NSButton?
    private var launchWindowController: NSWindowController?
    private var debugWindowController: NSWindowController?
    private var previewWindowController: PreviewWindowController?
    private var recordingFeedbackWindowController: RecordingFeedbackWindowController?
    private var pushToTalkWindowController: PushToTalkWindowController?
    private var activeAudioRecorder: AVFoundationAudioRecorder?
    private var inputLevelTimer: Timer?
    private var hasDetectedVoiceInput = false
    private var shouldStopRecordingWhenReady = false
    private var recordingStartedAt: Date?
    private let hotkeyMonitor = AppKitKeyboardShortcutMonitor()
    private let historyHotkeyMonitor = AppKitKeyboardShortcutMonitor()
    private var diagnosticHotkeyMonitors: [AppKitKeyboardShortcutMonitor] = []
    private var keyboardEventTap: KeyboardEventTap?
    private var permissionStatusTimer: Timer?
    private var lastPermissionStatusSnapshot: PermissionStatusSnapshot?
    private var hasOpenedMissingPermissionSettings = false
    private var isRecording = false {
        didSet {
            updateRecordingState()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        debugLogger.log("applicationDidFinishLaunching started; hotkeyDiagnosticsBuild=dispatcher-target-v1 bundlePath=\(Bundle.main.bundlePath) args=\(CommandLine.arguments.joined(separator: " "))")
        NSApp.setActivationPolicy(.regular)
        installMenuBarItem()
        showLaunchWindow()
        showDebugWindowIfNeeded()
        logPermissionStatusForDebug()
        requestInputMonitoringAccessIfNeeded()
        requestAccessibilityAccessIfNeeded()
        openMissingPermissionSettingsIfNeeded(reason: "launch")
        registerHotkeys(reason: "launch")
        startHotkeyDiagnosticsIfDebug()
        startPermissionStatusMonitoring()
        debugLogger.log("applicationDidFinishLaunching finished")
    }

    func applicationWillTerminate(_ notification: Notification) {
        debugLogger.log("applicationWillTerminate")
        permissionStatusTimer?.invalidate()
        permissionStatusTimer = nil
        hotkeyMonitor.stop()
        historyHotkeyMonitor.stop()
        diagnosticHotkeyMonitors.forEach { $0.stop() }
        keyboardEventTap?.stop()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        checkPermissionStatusForChanges(reason: "app became active")
    }

    private func installMenuBarItem() {
        debugLogger.log("installMenuBarItem started")
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "Voice"

        let menu = NSMenu()
        let recordItem = NSMenuItem(title: "Quick Paste Voice Input", action: #selector(recordVoiceInput), keyEquivalent: "r")
        let historyItem = NSMenuItem(title: "Voice Input History...", action: #selector(showVoiceInputHistory), keyEquivalent: "v")
        historyItem.keyEquivalentModifierMask = [.control, .shift]
        menu.addItem(recordItem)
        menu.addItem(NSMenuItem(title: "Show Push-to-Talk Button", action: #selector(showPushToTalkButton), keyEquivalent: "b"))
        let hotkeyItem = NSMenuItem(title: "Hotkey: Control-Option-Space", action: nil, keyEquivalent: "")
        menu.addItem(hotkeyItem)
        menu.addItem(NSMenuItem(title: "Hotkey Settings...", action: #selector(showHotkeySettings), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Start Hotkey Diagnostics", action: #selector(startHotkeyDiagnostics), keyEquivalent: ""))
        menu.addItem(historyItem)
        menu.addItem(NSMenuItem(title: "History Hotkey: Control-Shift-V", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Recording Settings...", action: #selector(showRecordingSettings), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Permission Status...", action: #selector(showPermissionStatus), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Voice Input Permissions...", action: #selector(openVoiceInputPermissionSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Privacy Settings...", action: #selector(openPrivacySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Input Monitoring Settings...", action: #selector(openInputMonitoringSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Set Repository Folder...", action: #selector(setRepositoryFolder), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Local Context Model Status...", action: #selector(showLocalContextModelStatus), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Rebuild Local Context Model...", action: #selector(rebuildLocalContextModelFromSources), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Export Local Dictionary...", action: #selector(exportLocalDictionary), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Import Local Dictionary...", action: #selector(importLocalDictionary), keyEquivalent: "i"))
        menu.addItem(NSMenuItem(title: "Export Local Context Model...", action: #selector(exportLocalContextModel), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Import Local Context Model...", action: #selector(importLocalContextModel), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Local Data Folder...", action: #selector(openLocalDataFolder), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Delete Local Dictionary...", action: #selector(deleteLocalDictionary), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Delete Local Context Model...", action: #selector(deleteLocalContextModel), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
        recordMenuItem = recordItem
        hotkeyMenuItem = hotkeyItem
        updateRecordingState()
        updateHotkeyMenuTitle()
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
        let recordButton = NSButton(title: "Quick Paste", target: self, action: #selector(recordVoiceInput))
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

    @objc private func recordVoiceInput() {
        debugLogger.log("recordVoiceInput requested")
        if isRecording {
            debugLogger.log("recordVoiceInput requested while active; stopping recording")
            activeAudioRecorder?.stopRecording()
            return
        }
        isRecording = true
        shouldStopRecordingWhenReady = false

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
                    self.recordingStartedAt = Date()
                    self.showRecordingFeedback(triggerMode: settings.voiceInputTriggerMode)
                    self.startInputLevelMonitoring()
                    self.debugLogger.log("recordVoiceInput recording started; waiting for user stop")
                    if self.shouldStopRecordingWhenReady {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 120_000_000)
                            audioRecorder.stopRecording()
                        }
                    }
                }
                let speechEngine = AppleSpeechEngine(
                    localeIdentifier: settings.effectiveSpeechLocaleIdentifier,
                    requiresOnDeviceRecognition: true,
                    recognitionHints: SpeechRecognitionHintsUseCase().hints(from: entries),
                    recognitionSnapshotHandler: { [debugLogger] snapshot, isFinal in
                        debugLogger.log("speech snapshot final=\(isFinal) text=\(snapshot)")
                    }
                )
                let voiceInputPipeline = VoiceInputPipeline(
                    audioRecorder: audioRecorder,
                    microphonePermissionProvider: AVFoundationMicrophonePermissionProvider(),
                    speechEngine: speechEngine,
                    refiner: JapanesePunctuationPromptRefiner(),
                    normalizationContext: NormalizationContext(entries: entries),
                    recordedAudioHandler: { [debugLogger] audio in
                        debugLogger.log(
                            "recordVoiceInput recorded audio duration=\(String(format: "%.2f", audio.durationSeconds))s bytes=\(audio.byteCount) format=\(audio.formatDescription)"
                        )
                    }
                )
                let result = try await voiceInputPipeline.run()
                await MainActor.run {
                    self.stopInputLevelMonitoring()
                    self.closeRecordingFeedback()
                    self.activeAudioRecorder = nil
                    self.recordingStartedAt = nil
                    self.isRecording = false
                    self.shouldStopRecordingWhenReady = false
                    self.debugLogger.log(
                        "recordVoiceInput completed; transcriptLength=\(result.transcript.text.count) correctedLength=\(result.preview.correctedPrompt.count); mode=quickPaste"
                    )
                }
                await MainActor.run {
                    do {
                        try self.insertConfirmedPrompt(ConfirmedPrompt(
                            promptToInsert: result.preview.correctedPrompt,
                            candidates: []
                        ))
                    } catch {
                        self.debugLogger.log("recordVoiceInput paste failed: \(error); opening preview")
                        self.openPreview(preview: result.preview, previewUseCase: previewUseCase)
                    }
                }
            } catch {
                await MainActor.run {
                    self.stopInputLevelMonitoring()
                    self.closeRecordingFeedback()
                    self.activeAudioRecorder = nil
                    self.recordingStartedAt = nil
                    self.isRecording = false
                    self.shouldStopRecordingWhenReady = false
                    self.debugLogger.log("recordVoiceInput failed: \(error)")
                    self.presentError(error)
                }
            }
        }
    }

    private func startVoiceInputFromShortcut() {
        guard !isRecording else {
            debugLogger.log("voice input push-to-talk keyDown ignored because recording is already active")
            return
        }
        debugLogger.log("voice input push-to-talk keyDown received; starting")
        recordVoiceInput()
    }

    private func stopVoiceInputFromShortcut() {
        guard isRecording else {
            debugLogger.log("voice input push-to-talk keyUp ignored because no recording is active")
            return
        }
        debugLogger.log("voice input push-to-talk keyUp received; stopping recording")
        if let activeAudioRecorder {
            activeAudioRecorder.stopRecording()
        } else {
            shouldStopRecordingWhenReady = true
            debugLogger.log("voice input push-to-talk keyUp received before recorder was ready; queued stop")
        }
    }

    private func updateRecordingState() {
        statusItem?.button?.title = isRecording ? "Voice..." : "Voice"
        recordMenuItem?.title = isRecording ? "Stop Voice Input" : "Quick Paste Voice Input"
        recordMenuItem?.isEnabled = true
        launchRecordButton?.title = isRecording ? "Stop" : "Quick Paste"
        pushToTalkWindowController?.setRecording(isRecording)
    }

    private func updateHotkeyMenuTitle(settings: AppSettings? = nil) {
        let currentSettings = settings ?? ((try? loadSettings()) ?? AppSettings())
        hotkeyMenuItem?.title = "Hotkey: \(currentSettings.voiceInputShortcut.displayName) (\(currentSettings.voiceInputTriggerMode.displayName))"
    }

    @objc private func showPushToTalkButton() {
        if let pushToTalkWindowController {
            pushToTalkWindowController.showWindow(nil)
            return
        }
        let controller = PushToTalkWindowController(
            startAction: { [weak self] in
                self?.debugLogger.log("push-to-talk button pressed; starting")
                self?.startVoiceInputFromShortcut()
            },
            stopAction: { [weak self] in
                self?.debugLogger.log("push-to-talk button released; stopping")
                self?.stopVoiceInputFromShortcut()
            }
        )
        pushToTalkWindowController = controller
        controller.showWindow(nil)
    }

    private func startHotkeyDiagnosticsIfDebug() {
        guard debugLogger.enabled else {
            return
        }
        startHotkeyDiagnostics()
    }

    @objc private func startHotkeyDiagnostics() {
        debugLogger.log("hotkey diagnostics starting")
        diagnosticHotkeyMonitors.forEach { $0.stop() }
        diagnosticHotkeyMonitors = []

        let diagnosticShortcuts: [(String, KeyboardShortcut)] = [
            ("diagnostic/control-option-s", KeyboardShortcut(key: "s", modifiers: [.control, .option])),
            ("diagnostic/control-shift-d", KeyboardShortcut(key: "d", modifiers: [.control, .shift])),
            ("diagnostic/control-option-d", KeyboardShortcut(key: "d", modifiers: [.control, .option]))
        ]
        for (label, shortcut) in diagnosticShortcuts {
            let monitor = AppKitKeyboardShortcutMonitor()
            monitor.start(
                shortcut: shortcut,
                onTrigger: { [debugLogger] in
                    debugLogger.log("hotkey diagnostics carbon pressed label=\(label)")
                },
                onRelease: { [debugLogger] in
                    debugLogger.log("hotkey diagnostics carbon released label=\(label)")
                }
            )
            diagnosticHotkeyMonitors.append(monitor)
        }

        if keyboardEventTap == nil {
            keyboardEventTap = KeyboardEventTap(debugLogger: debugLogger)
        }
        keyboardEventTap?.start()
        debugLogger.log("hotkey diagnostics ready; try Control-Option-Space, Control-Shift-S, Control-Option-S, Control-Shift-D, Control-Option-D")
    }

    private func registerHotkeys(reason: String) {
        AppKitKeyboardShortcutMonitor.debugLogger = debugLogger
        hotkeyMonitor.stop()
        historyHotkeyMonitor.stop()
        let settings = (try? loadSettings()) ?? AppSettings()
        updateHotkeyMenuTitle(settings: settings)

        debugLogger.log("registering voice input hotkey \(settings.voiceInputShortcut.displayName) triggerMode=\(settings.voiceInputTriggerMode.rawValue) reason=\(reason)")
        let releaseHandler: (() -> Void)? = settings.voiceInputTriggerMode == .pressAndHold
            ? { [weak self] in
                Task { @MainActor in
                    self?.handleVoiceInputHotkey(event: .released)
                }
            }
            : nil
        hotkeyMonitor.start(
            shortcut: settings.voiceInputShortcut,
            onTrigger: { [weak self] in
                Task { @MainActor in
                    self?.handleVoiceInputHotkey(event: .pressed)
                }
            },
            onRelease: releaseHandler
        )
        debugLogger.log("registering voice input history hotkey Control-Shift-V reason=\(reason)")
        historyHotkeyMonitor.start(shortcut: .defaultVoiceInputHistory) { [weak self] in
            Task { @MainActor in
                self?.debugLogger.log("voice input history hotkey triggered")
                self?.showVoiceInputHistory()
            }
        }
    }

    private func handleVoiceInputHotkey(event: VoiceInputHotkeyEvent) {
        let settings = (try? loadSettings()) ?? AppSettings()
        let action = VoiceInputHotkeyUseCase().action(
            triggerMode: settings.voiceInputTriggerMode,
            event: event,
            isRecording: isRecording
        )
        debugLogger.log("voice input hotkey event=\(event) triggerMode=\(settings.voiceInputTriggerMode.rawValue) action=\(action)")

        switch action {
        case .startRecording:
            startVoiceInputFromShortcut()
        case .stopRecording:
            stopVoiceInputFromShortcut()
        case .none:
            break
        }
    }

    private func startPermissionStatusMonitoring() {
        lastPermissionStatusSnapshot = currentPermissionStatus()
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissionStatusForChanges(reason: "poll")
            }
        }
        permissionStatusTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func checkPermissionStatusForChanges(reason: String) {
        let status = currentPermissionStatus()
        guard let lastPermissionStatusSnapshot else {
            self.lastPermissionStatusSnapshot = status
            debugLogger.log("permission status baseline \(permissionStatusDescription(status)) reason=\(reason)")
            return
        }
        guard status != lastPermissionStatusSnapshot else {
            return
        }

        debugLogger.log(
            "permission status changed \(permissionStatusDescription(lastPermissionStatusSnapshot)) -> \(permissionStatusDescription(status)) reason=\(reason)"
        )
        self.lastPermissionStatusSnapshot = status

        if lastPermissionStatusSnapshot.inputMonitoring != .trusted,
           status.inputMonitoring == .trusted
        {
            registerHotkeys(reason: "input monitoring became trusted")
            if debugLogger.enabled {
                startHotkeyDiagnostics()
            }
        }
    }

    private func showRecordingFeedback(triggerMode: VoiceInputTriggerMode) {
        let controller = RecordingFeedbackWindowController(triggerMode: triggerMode) { [weak self] in
            Task { @MainActor in
                self?.recordVoiceInput()
            }
        }
        recordingFeedbackWindowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        controller.update(level: nil, hasDetectedVoice: false, elapsedSeconds: 0)
    }

    private func closeRecordingFeedback() {
        recordingFeedbackWindowController?.close()
        recordingFeedbackWindowController = nil
    }

    private func startInputLevelMonitoring() {
        stopInputLevelMonitoring()
        let timer = Timer(timeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateInputLevelFeedback()
            }
        }
        inputLevelTimer = timer
        RunLoop.main.add(timer, forMode: .common)
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
            hasDetectedVoice: hasDetectedVoiceInput,
            elapsedSeconds: recordingStartedAt.map { Date().timeIntervalSince($0) } ?? 0
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
        let learningScope = (try? loadSettings().preferredLearningScope) ?? .user
        let controller = PreviewWindowController(
            preview: preview,
            previewUseCase: previewUseCase,
            editLearningUseCase: PromptEditLearningUseCase(
                previewUseCase: previewUseCase
            ),
            suggestedLearningScope: learningScope,
            onConfirmedPaste: { [weak self] confirmed in
                self?.recordVoiceInputHistory(
                    prompt: confirmed.promptToInsert
                )
            }
        )
        previewWindowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func insertConfirmedPrompt(_ confirmed: ConfirmedPrompt) throws {
        do {
            let insertion = PromptInsertionUseCase(insertionController: AccessibilityTextInsertionController())
            try insertion.insert(confirmed, explicitConfirmation: true)
            recordVoiceInputHistory(prompt: confirmed.promptToInsert)
            try CandidateApprovalDialogController().approveCandidatesIfRequested(confirmed.candidates)
        } catch AccessibilityTextInsertionError.accessibilityPermissionRequired {
            try PromptInsertionUseCase(
                insertionController: PasteboardTextInsertionController()
            ).insert(confirmed, explicitConfirmation: true)
            recordVoiceInputHistory(prompt: confirmed.promptToInsert)
            showAccessibilityFallbackAlert()
            try CandidateApprovalDialogController().approveCandidatesIfRequested(confirmed.candidates)
        }
    }

    private func recordVoiceInputHistory(prompt: String) {
        do {
            try voiceInputHistoryUseCase().record(prompt: prompt)
        } catch {
            debugLogger.log("voice input history record failed: \(error)")
        }
    }

    private func showAccessibilityFallbackAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Prompt copied"
        alert.informativeText = "Enable Accessibility access for Voice Agent Input in System Settings to paste automatically. For now, press Command-V in the target app."
        alert.runModal()
    }

    private func loadDictionaryEntries() throws -> [DictionaryEntry] {
        try DictionaryEntryLoadingUseCase(
            repository: try approvedDictionaryRepository(),
            localContextModelRepository: try localContextModelRepository()
        ).loadEntries()
    }

    private func loadSettings() throws -> AppSettings {
        try settingsUseCase().loadSettings()
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

    private func voiceInputHistoryUseCase() throws -> VoiceInputHistoryUseCase {
        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        return try VoiceInputHistoryUseCase(repository: store.voiceInputHistoryRepository())
    }

    private func approvedDictionaryRepository() throws -> JSONDictionaryRepository {
        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        return try store.repository()
    }

    private func localContextModelRepository() throws -> JSONLocalContextModelRepository {
        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        return try store.localContextModelRepository()
    }

    private func logPermissionStatusForDebug() {
        let status = currentPermissionStatus()
        debugLogger.log("permission status \(permissionStatusDescription(status))")
    }

    private func currentPermissionStatus() -> PermissionStatusSnapshot {
        PermissionStatusUseCase(
            microphonePermissionProvider: AVFoundationMicrophonePermissionProvider(),
            speechRecognitionPermissionProvider: SFSpeechRecognitionPermissionProvider(),
            accessibilityPermissionProvider: AXAccessibilityPermissionProvider(),
            inputMonitoringPermissionProvider: CGEventInputMonitoringPermissionProvider()
        ).currentStatus()
    }

    private func permissionStatusDescription(_ status: PermissionStatusSnapshot) -> String {
        "microphone=\(status.microphone.rawValue) speech=\(status.speechRecognition.rawValue) accessibility=\(status.accessibility.rawValue) inputMonitoring=\(status.inputMonitoring.rawValue)"
    }

    private func requestInputMonitoringAccessIfNeeded() {
        let provider = CGEventInputMonitoringPermissionProvider()
        guard provider.currentStatus() != .trusted else {
            return
        }
        debugLogger.log("input monitoring is not trusted; requesting access for global hotkeys")
        let requestedStatus = provider.requestAccess()
        debugLogger.log("input monitoring request result=\(requestedStatus.rawValue)")
    }

    private func requestAccessibilityAccessIfNeeded() {
        guard AXAccessibilityPermissionProvider().currentStatus() != .trusted else {
            return
        }
        debugLogger.log("accessibility is not trusted; requesting access for automatic paste")
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        debugLogger.log("accessibility request result=\(isTrusted ? "trusted" : "notTrusted")")
    }

    private func openMissingPermissionSettingsIfNeeded(reason: String, force: Bool = false) {
        let status = currentPermissionStatus()
        let needsAccessibility = status.accessibility != .trusted
        let needsInputMonitoring = status.inputMonitoring != .trusted
        guard needsAccessibility || needsInputMonitoring else {
            debugLogger.log("permission settings not opened reason=\(reason) missing=none")
            if force {
                openPrivacySettings()
            }
            return
        }
        guard force || !hasOpenedMissingPermissionSettings else {
            debugLogger.log("permission settings already opened once; skipping reason=\(reason)")
            return
        }

        hasOpenedMissingPermissionSettings = true
        let missing = [
            needsAccessibility ? "accessibility" : nil,
            needsInputMonitoring ? "inputMonitoring" : nil
        ].compactMap { $0 }.joined(separator: ",")
        debugLogger.log("opening permission settings reason=\(reason) missing=\(missing)")

        if needsInputMonitoring {
            openInputMonitoringSettings()
        }
        if needsAccessibility {
            let delay: TimeInterval = needsInputMonitoring ? 0.8 : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.openAccessibilitySettings()
            }
        }
    }

    @objc private func showVoiceInputHistory() {
        do {
            let entries = try voiceInputHistoryUseCase().recentEntries()
            guard !entries.isEmpty else {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = "No voice input history yet"
                alert.informativeText = "Recorded prompts appear here after they are pasted or copied."
                alert.runModal()
                return
            }

            let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 520, height: 28), pullsDown: false)
            for entry in entries {
                let title = entry.prompt.count > 80
                    ? String(entry.prompt.prefix(77)) + "..."
                    : entry.prompt
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.representedObject = entry.prompt
                popup.menu?.addItem(item)
            }

            let alert = NSAlert()
            alert.messageText = "Voice input history"
            alert.informativeText = "Choose a past voice input to paste into the focused app."
            alert.accessoryView = popup
            alert.addButton(withTitle: "Paste")
            alert.addButton(withTitle: "Cancel")

            guard
                alert.runModal() == .alertFirstButtonReturn,
                let prompt = popup.selectedItem?.representedObject as? String
            else {
                return
            }

            try insertConfirmedPrompt(
                ConfirmedPrompt(promptToInsert: prompt, candidates: [])
            )
        } catch {
            presentError(error)
        }
    }

    @objc private func setRepositoryFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a Git repository folder for repository vocabulary learning."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try settingsUseCase().saveRepositoryPath(url.path)
        } catch {
            presentError(error)
        }
    }

    @objc private func showHotkeySettings() {
        do {
            let settingsUseCase = try settingsUseCase()
            let settings = try settingsUseCase.loadSettings()

            let keyPicker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 28), pullsDown: false)
            for key in Self.supportedVoiceInputHotkeyKeys {
                let item = NSMenuItem(title: KeyboardShortcut.displayName(forKey: key), action: nil, keyEquivalent: "")
                item.representedObject = key
                keyPicker.menu?.addItem(item)
            }
            keyPicker.selectItem(withTitle: KeyboardShortcut.displayName(forKey: settings.voiceInputShortcut.key))

            let triggerPicker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 28), pullsDown: false)
            for triggerMode in VoiceInputTriggerMode.allCases {
                let item = NSMenuItem(title: triggerMode.displayName, action: nil, keyEquivalent: "")
                item.representedObject = triggerMode.rawValue
                triggerPicker.menu?.addItem(item)
            }
            triggerPicker.selectItem(withTitle: settings.voiceInputTriggerMode.displayName)

            let controlCheckbox = NSButton(checkboxWithTitle: "Control", target: nil, action: nil)
            let optionCheckbox = NSButton(checkboxWithTitle: "Option", target: nil, action: nil)
            let shiftCheckbox = NSButton(checkboxWithTitle: "Shift", target: nil, action: nil)
            let commandCheckbox = NSButton(checkboxWithTitle: "Command", target: nil, action: nil)
            controlCheckbox.state = settings.voiceInputShortcut.modifiers.contains(.control) ? .on : .off
            optionCheckbox.state = settings.voiceInputShortcut.modifiers.contains(.option) ? .on : .off
            shiftCheckbox.state = settings.voiceInputShortcut.modifiers.contains(.shift) ? .on : .off
            commandCheckbox.state = settings.voiceInputShortcut.modifiers.contains(.command) ? .on : .off

            let modifierStack = NSStackView(views: [
                controlCheckbox,
                optionCheckbox,
                shiftCheckbox,
                commandCheckbox
            ])
            modifierStack.orientation = .horizontal
            modifierStack.alignment = .centerY
            modifierStack.spacing = 8

            let stack = AppLayout.formStack()
            stack.addArrangedSubview(AppLayout.formRow(label: "Key", view: keyPicker))
            stack.addArrangedSubview(AppLayout.formRow(label: "Trigger", view: triggerPicker))
            stack.addArrangedSubview(AppLayout.formRow(label: "Modifiers", view: modifierStack))

            let alert = NSAlert()
            alert.messageText = "Hotkey settings"
            alert.informativeText = "Press and Hold records until key release. Toggle Recording starts on the first press and stops on the next press or the Stop button."
            alert.accessoryView = stack
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Cancel")

            guard
                alert.runModal() == .alertFirstButtonReturn,
                let key = keyPicker.selectedItem?.representedObject as? String,
                let triggerRawValue = triggerPicker.selectedItem?.representedObject as? String,
                let triggerMode = VoiceInputTriggerMode(rawValue: triggerRawValue)
            else {
                return
            }

            var modifiers: KeyboardShortcut.Modifiers = []
            if controlCheckbox.state == .on {
                modifiers.insert(.control)
            }
            if optionCheckbox.state == .on {
                modifiers.insert(.option)
            }
            if shiftCheckbox.state == .on {
                modifiers.insert(.shift)
            }
            if commandCheckbox.state == .on {
                modifiers.insert(.command)
            }
            guard !modifiers.isEmpty else {
                let modifierAlert = NSAlert()
                modifierAlert.alertStyle = .warning
                modifierAlert.messageText = "Choose at least one modifier"
                modifierAlert.informativeText = "Global voice input hotkeys should include Control, Option, Shift, or Command."
                modifierAlert.runModal()
                return
            }

            let saved = try settingsUseCase.saveVoiceInputHotkey(
                shortcut: KeyboardShortcut(key: key, modifiers: modifiers),
                triggerMode: triggerMode
            )
            updateHotkeyMenuTitle(settings: saved)
            registerHotkeys(reason: "hotkey settings changed")
        } catch {
            presentError(error)
        }
    }

    @objc private func showRecordingSettings() {
        do {
            let settingsUseCase = try settingsUseCase()
            let settings = try settingsUseCase.loadSettings()

            let durationField = AppLayout.textField(
                String(format: "%.0f", settings.effectiveRecordingDurationSeconds)
            )
            let localeField = AppLayout.textField(settings.effectiveSpeechLocaleIdentifier)
            let stack = AppLayout.formStack()
            stack.addArrangedSubview(AppLayout.formRow(label: "Recording seconds", view: durationField))
            stack.addArrangedSubview(AppLayout.formRow(label: "Speech locale", view: localeField))

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
            accessibilityPermissionProvider: AXAccessibilityPermissionProvider(),
            inputMonitoringPermissionProvider: CGEventInputMonitoringPermissionProvider()
        ).currentStatus()

        let alert = NSAlert()
        alert.messageText = "Permission status"
        alert.informativeText = """
        Microphone: \(status.microphone.rawValue)
        Speech recognition: \(status.speechRecognition.rawValue)
        Accessibility paste: \(status.accessibility.rawValue)
        Input monitoring hotkeys: \(status.inputMonitoring.rawValue)
        """
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open Settings")
        if alert.runModal() == .alertSecondButtonReturn {
            openMissingPermissionSettingsIfNeeded(reason: "permission status alert", force: true)
        }
    }

    @objc private func openVoiceInputPermissionSettings() {
        requestInputMonitoringAccessIfNeeded()
        requestAccessibilityAccessIfNeeded()
        openMissingPermissionSettingsIfNeeded(reason: "permission menu", force: true)
    }

    @objc private func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            openPrivacySettings()
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func openInputMonitoringSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else {
            openPrivacySettings()
            return
        }
        NSWorkspace.shared.open(url)
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

    @objc private func exportLocalContextModel() {
        do {
            let model = try LocalContextModelDataUseCase(
                repository: localContextModelRepository()
            ).exportModel()

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "voice-agent-input-local-context-model.json"
            panel.message = "Export the local context model used for STT hints and post-STT transforms."

            guard panel.runModal() == .OK, let url = panel.url else {
                return
            }

            try LocalContextModelDocumentCodec()
                .encode(model)
                .write(to: url, options: [.atomic])
        } catch {
            presentError(error)
        }
    }

    @objc private func importLocalContextModel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        panel.message = "Import a local context model JSON document."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let model = try LocalContextModelDocumentCodec()
                .decode(try Data(contentsOf: url))
            try LocalContextModelDataUseCase(
                repository: localContextModelRepository()
            ).importModel(model)
        } catch {
            presentError(error)
        }
    }

    @objc private func showLocalContextModelStatus() {
        do {
            let model = try LocalContextModelDataUseCase(
                repository: localContextModelRepository()
            ).exportModel()

            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Local context model status"
            alert.informativeText = localContextModelStatusText(model: model)
            alert.runModal()
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

    @objc private func rebuildLocalContextModelFromSources() {
        do {
            guard let selection = try promptForLearningSourceSelection(
                title: "Rebuild local context model",
                informativeText: "Selected local sources refresh the model used for STT hints and post-STT transforms. Nothing is uploaded, and no candidate approval is required.",
                confirmButtonTitle: "Rebuild"
            ) else {
                return
            }
            guard !selection.isEmpty else {
                showNoLearningSourceSelectedAlert()
                return
            }

            let run = try rebuildLocalContextModel(selection: selection)
            showLocalContextModelRebuiltAlert(result: run.result, model: run.model)
        } catch {
            presentError(error)
        }
    }

    private func promptForLearningSourceSelection(
        title: String,
        informativeText: String,
        confirmButtonTitle: String
    ) throws -> LearningSourceSelection? {
        let repositoryURL = configuredRepositoryURL()
        let agentHistoryCheckbox = NSButton(
            checkboxWithTitle: "Codex / Claude local sessions",
            target: nil,
            action: nil
        )
        agentHistoryCheckbox.state = .on

        let repositoryCheckbox = NSButton(
            checkboxWithTitle: "Git repository vocabulary",
            target: nil,
            action: nil
        )
        repositoryCheckbox.state = repositoryURL == nil ? .off : .on
        repositoryCheckbox.isEnabled = repositoryURL != nil

        let repositoryLabel = NSTextField(labelWithString: repositoryURL?.path ?? "No repository folder configured")
        repositoryLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        repositoryLabel.textColor = repositoryURL == nil ? .secondaryLabelColor : .labelColor
        repositoryLabel.lineBreakMode = .byTruncatingMiddle
        repositoryLabel.maximumNumberOfLines = 1
        repositoryLabel.preferredMaxLayoutWidth = AppLayout.accessoryWidth
        repositoryLabel.translatesAutoresizingMaskIntoConstraints = false
        repositoryLabel.widthAnchor.constraint(equalToConstant: AppLayout.accessoryWidth).isActive = true

        let stack = AppLayout.formStack()
        stack.addArrangedSubview(agentHistoryCheckbox)
        stack.addArrangedSubview(repositoryCheckbox)
        stack.addArrangedSubview(repositoryLabel)

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = informativeText
        alert.accessoryView = stack
        alert.addButton(withTitle: confirmButtonTitle)
        if repositoryURL == nil {
            alert.addButton(withTitle: "Set Repository Folder")
        }
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            return LearningSourceSelection(
                includeAgentHistory: agentHistoryCheckbox.state == .on,
                includeRepositoryVocabulary: repositoryCheckbox.state == .on && repositoryURL != nil
            )
        }
        if repositoryURL == nil, response == .alertSecondButtonReturn {
            setRepositoryFolder()
        }
        return nil
    }

    private func showNoLearningSourceSelectedAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "No learning sources selected"
        alert.informativeText = "Choose at least one local source to scan."
        alert.runModal()
    }

    private func rebuildLocalContextModel(
        selection: LearningSourceSelection
    ) throws -> (result: AgentHistoryLearningModeResult, model: LocalContextModel) {
        let historyProvider = LocalAgentHistoryTextProvider()
        let existingEntries = try loadDictionaryEntries()
        let approvedEntries = try approvedDictionaryRepository().loadEntries()
        let learningScope = try loadSettings().preferredLearningScope
        let learningSources = try configuredLearningSources(
            selection: selection,
            historyProvider: historyProvider
        )

        let result = try AgentHistoryLearningModeUseCase(
            learningSources: learningSources,
            dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
        ).generateCandidates(scope: learningScope, existingEntries: existingEntries)
        let sourceNames = learningSources.map { $0.sourceKind.rawValue }.joined(separator: ",")
        debugLogger.log("dictionary training scanned \(historyProvider.historyFileURLs().count) local history files, loaded \(result.scannedTextCount) source texts, sourceTextCounts=\(result.sourceTextCounts), skipped \(result.skippedExistingCandidateCount) existing candidates, scope=\(learningScope.rawValue), sources=\(sourceNames)")

        let localContextModel = try LocalContextModelDataUseCase(
            repository: localContextModelRepository(),
            buildUseCase: LocalContextModelBuildUseCase(approvedEntries: approvedEntries)
        ).rebuildModel(learningResult: result)
        debugLogger.log("local context model rebuilt with \(localContextModel.entries.count) entries and \(localContextModel.generatedCandidateCount) generated candidates")

        return (result, localContextModel)
    }

    private func showLocalContextModelRebuiltAlert(
        result: AgentHistoryLearningModeResult,
        model: LocalContextModel
    ) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Local context model rebuilt"
        alert.informativeText = localContextModelStatusText(
            model: model,
            scannedTextCount: result.scannedTextCount,
            generatedCandidateCount: result.candidates.count
        )
        alert.runModal()
    }

    private func localContextModelStatusText(
        model: LocalContextModel,
        scannedTextCount: Int? = nil,
        generatedCandidateCount: Int? = nil
    ) -> String {
        let rebuiltText = model.lastRebuiltAt.map(Self.localContextModelDateFormatter.string(from:)) ?? "never"
        let sourceText = model.sourceKinds.isEmpty ? "none" : model.sourceKinds.joined(separator: ", ")
        let totalSourceTexts = model.sourceTextCounts.values.reduce(0, +)
        let sourceCounts = model.sourceTextCounts
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
        let scannedTextLine = scannedTextCount.map { "Scanned \($0) local source texts." } ?? "Stored source texts: \(totalSourceTexts)."
        let generatedCount = generatedCandidateCount ?? model.generatedCandidateCount
        let sourceCountLine = sourceCounts.isEmpty ? "Source text counts: none." : "Source text counts: \(sourceCounts)."
        let warnings = LocalContextModelStatusUseCase()
            .warnings(model: model, configuredRepositoryPath: try? loadSettings().repositoryPath)
        let warningText = warnings.isEmpty ? "Status warnings: none." : "Status warnings: \(warnings.joined(separator: " "))"

        return """
        Last rebuild time: \(rebuiltText).
        Source kinds: \(sourceText).
        \(scannedTextLine)
        \(sourceCountLine)
        Generated candidates: \(generatedCount).
        Runtime model entries: \(model.entries.count).
        \(warningText)
        """
    }

    private static let localContextModelDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()

    private func configuredLearningSources(
        selection: LearningSourceSelection,
        historyProvider: LocalAgentHistoryTextProvider
    ) throws -> [any LearningSource] {
        var sources: [any LearningSource] = []
        if selection.includeAgentHistory {
            sources.append(historyProvider)
        }
        if selection.includeRepositoryVocabulary, let repositoryURL = configuredRepositoryURL() {
            let provider = GitRepositoryContextProvider()
            sources.append(RepositoryVocabularyLearningSource(
                startingURL: repositoryURL,
                repositoryContextProvider: provider,
                repositoryVocabularyFilePathProvider: provider
            ))
        }
        return sources
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

    @objc private func deleteLocalContextModel() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Delete local context model?"
        alert.informativeText = "This removes the learned context model used for STT hints and post-STT transforms. Approved dictionary entries and bundled seed terms are not deleted."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        do {
            try LocalContextModelDataUseCase(
                repository: localContextModelRepository()
            ).deleteLocalContextModel()
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
    nonisolated(unsafe) static var debugLogger: AppDebugLogger?
    nonisolated(unsafe) private static var nextHotKeyID: UInt32 = 1
    private static let signature = OSType(
        UInt32(Character("V").asciiValue!) << 24
            | UInt32(Character("A").asciiValue!) << 16
            | UInt32(Character("I").asciiValue!) << 8
            | UInt32(Character("H").asciiValue!)
    )

    private var eventHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var eventTap: CFMachPort?
    private var eventTapRunLoopSource: CFRunLoopSource?
    private var hotKeyID: EventHotKeyID?
    nonisolated(unsafe) private var eventTapKeyCode: Int?
    nonisolated(unsafe) private var eventTapModifiers: KeyboardShortcut.Modifiers = []
    private var keyCode: Int?
    private var modifiers: KeyboardShortcut.Modifiers = []
    private var onTrigger: (() -> Void)?
    private var onRelease: (() -> Void)?
    private var isPressed = false

    func start(shortcut: KeyboardShortcut, onTrigger: @escaping () -> Void, onRelease: (() -> Void)? = nil) {
        stop()
        self.onTrigger = onTrigger
        self.onRelease = onRelease

        guard let keyCode = Self.carbonKeyCode(for: shortcut.key) else {
            Self.debugLogger?.log("carbon hotkey registration failed; unsupported key=\(shortcut.key)")
            return
        }
        self.keyCode = keyCode
        modifiers = shortcut.modifiers
        eventTapKeyCode = keyCode
        eventTapModifiers = shortcut.modifiers

        let id = EventHotKeyID(signature: Self.signature, id: Self.nextHotKeyID)
        Self.nextHotKeyID += 1
        hotKeyID = id

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        let eventTarget = GetEventDispatcherTarget()
        let installStatus = InstallEventHandler(
            eventTarget,
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }
                let monitor = Unmanaged<AppKitKeyboardShortcutMonitor>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                var eventHotKeyID = EventHotKeyID()
                let parameterStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &eventHotKeyID
                )
                guard parameterStatus == noErr else {
                    return noErr
                }
                Task { @MainActor in
                    monitor.handleCarbonHotKey(
                        eventKind: GetEventKind(event),
                        eventHotKeyID: eventHotKeyID
                    )
                }
                return noErr
            },
            eventTypes.count,
            &eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        guard installStatus == noErr else {
            Self.debugLogger?.log("carbon hotkey handler install failed status=\(installStatus)")
            stop()
            return
        }

        var registeredHotKeyRef: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            UInt32(keyCode),
            Self.carbonModifiers(for: shortcut.modifiers),
            id,
            eventTarget,
            OptionBits(0),
            &registeredHotKeyRef
        )
        guard registerStatus == noErr else {
            Self.debugLogger?.log("carbon hotkey registration failed status=\(registerStatus) key=\(shortcut.key) modifiers=\(Self.modifierDescription(shortcut.modifiers))")
            stop()
            return
        }
        eventHotKeyRef = registeredHotKeyRef
        Self.debugLogger?.log("carbon hotkey registered target=dispatcher key=\(shortcut.key) keyCode=\(keyCode) modifiers=\(Self.modifierDescription(shortcut.modifiers)) id=\(id.id)")
        startEventTapFallback(shortcut: shortcut, keyCode: keyCode)
    }

    func stop() {
        if let eventTapRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapRunLoopSource, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        if let eventHotKeyRef {
            UnregisterEventHotKey(eventHotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        eventTap = nil
        eventTapRunLoopSource = nil
        eventHotKeyRef = nil
        eventHandlerRef = nil
        hotKeyID = nil
        eventTapKeyCode = nil
        eventTapModifiers = []
        keyCode = nil
        modifiers = []
        onTrigger = nil
        onRelease = nil
        isPressed = false
    }

    private func startEventTapFallback(shortcut: KeyboardShortcut, keyCode: Int) {
        guard CGPreflightListenEventAccess() else {
            Self.debugLogger?.log("cgevent hotkey fallback not started; input monitoring not trusted key=\(shortcut.key) modifiers=\(Self.modifierDescription(shortcut.modifiers))")
            return
        }

        let eventsOfInterest =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
        let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }
            let monitor = Unmanaged<AppKitKeyboardShortcutMonitor>
                .fromOpaque(userInfo)
                .takeUnretainedValue()
                let shouldConsume = monitor.handleEventTap(type: type, event: event)
            if shouldConsume {
                return nil
            }
            return Unmanaged.passUnretained(event)
        }
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        let tapOptions: CGEventTapOptions
        let createdEventTap: CFMachPort?
        if let activeEventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventsOfInterest),
            callback: eventTapCallback,
            userInfo: userInfo
        ) {
            tapOptions = .defaultTap
            createdEventTap = activeEventTap
        } else if let listenOnlyEventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventsOfInterest),
            callback: eventTapCallback,
            userInfo: userInfo
        ) {
            tapOptions = .listenOnly
            createdEventTap = listenOnlyEventTap
        } else {
            Self.debugLogger?.log("cgevent hotkey fallback create failed for active and listenOnly taps key=\(shortcut.key) modifiers=\(Self.modifierDescription(shortcut.modifiers))")
            return
        }

        guard let eventTap = createdEventTap else {
            return
        }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
            CFMachPortInvalidate(eventTap)
            Self.debugLogger?.log("cgevent hotkey fallback run loop source create failed key=\(shortcut.key)")
            return
        }

        self.eventTap = eventTap
        eventTapRunLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        Self.debugLogger?.log("cgevent hotkey fallback started options=\(tapOptions == .listenOnly ? "listenOnly" : "active") key=\(shortcut.key) keyCode=\(keyCode) modifiers=\(Self.modifierDescription(shortcut.modifiers))")
    }

    private nonisolated func handleEventTap(type: CGEventType, event: CGEvent) -> Bool {
        let eventKeyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let eventFlags = event.flags
        Task { @MainActor in
            self.handleEventTapOnMainActor(type: type, keyCode: eventKeyCode, flags: eventFlags)
        }
        return matchesEventTap(type: type, keyCode: eventKeyCode, flags: eventFlags)
    }

    private nonisolated func matchesEventTap(type: CGEventType, keyCode eventKeyCode: Int, flags: CGEventFlags) -> Bool {
        guard let expectedKeyCode = eventTapKeyCode else {
            return false
        }
        guard eventKeyCode == expectedKeyCode else {
            return false
        }
        if type == .keyUp {
            return true
        }
        return Self.modifiersMatch(flags: flags, modifiers: eventTapModifiers)
    }

    private func handleEventTapOnMainActor(type: CGEventType, keyCode eventKeyCode: Int, flags: CGEventFlags) {
        guard let keyCode, eventKeyCode == keyCode else {
            return
        }

        switch type {
        case .keyDown:
            guard Self.modifiersMatch(flags: flags, modifiers: modifiers) else {
                return
            }
            if !isPressed {
                Self.debugLogger?.log("cgevent hotkey pressed keyCode=\(eventKeyCode) modifiers=\(Self.modifierDescription(modifiers))")
                isPressed = true
                onTrigger?()
            }
        case .keyUp:
            if isPressed {
                Self.debugLogger?.log("cgevent hotkey released keyCode=\(eventKeyCode) modifiers=\(Self.modifierDescription(modifiers)) eventModifiers=\(Self.cgModifierDescription(flags))")
                isPressed = false
                onRelease?()
            }
        default:
            break
        }
    }

    private func handleCarbonHotKey(eventKind: UInt32, eventHotKeyID: EventHotKeyID) {
        guard
            let hotKeyID,
            eventHotKeyID.signature == hotKeyID.signature,
            eventHotKeyID.id == hotKeyID.id
        else {
            return
        }

        switch eventKind {
        case UInt32(kEventHotKeyPressed):
            if !isPressed {
                Self.debugLogger?.log("carbon hotkey pressed id=\(eventHotKeyID.id)")
                isPressed = true
                onTrigger?()
            }
        case UInt32(kEventHotKeyReleased):
            if isPressed {
                Self.debugLogger?.log("carbon hotkey released id=\(eventHotKeyID.id)")
                isPressed = false
                onRelease?()
            }
        default:
            break
        }
    }

    private static func carbonKeyCode(for key: String) -> Int? {
        switch key.lowercased() {
        case "a":
            kVK_ANSI_A
        case "b":
            kVK_ANSI_B
        case "c":
            kVK_ANSI_C
        case "s":
            kVK_ANSI_S
        case "d":
            kVK_ANSI_D
        case "e":
            kVK_ANSI_E
        case "f":
            kVK_ANSI_F
        case "g":
            kVK_ANSI_G
        case "h":
            kVK_ANSI_H
        case "i":
            kVK_ANSI_I
        case "j":
            kVK_ANSI_J
        case "k":
            kVK_ANSI_K
        case "l":
            kVK_ANSI_L
        case "m":
            kVK_ANSI_M
        case "n":
            kVK_ANSI_N
        case "o":
            kVK_ANSI_O
        case "p":
            kVK_ANSI_P
        case "q":
            kVK_ANSI_Q
        case "r":
            kVK_ANSI_R
        case "t":
            kVK_ANSI_T
        case "u":
            kVK_ANSI_U
        case "v":
            kVK_ANSI_V
        case "w":
            kVK_ANSI_W
        case "x":
            kVK_ANSI_X
        case "y":
            kVK_ANSI_Y
        case "z":
            kVK_ANSI_Z
        case "space":
            kVK_Space
        default:
            nil
        }
    }

    private static func carbonModifiers(for modifiers: KeyboardShortcut.Modifiers) -> UInt32 {
        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        return carbonModifiers
    }

    private static func modifierDescription(_ modifiers: KeyboardShortcut.Modifiers) -> String {
        var names: [String] = []
        if modifiers.contains(.control) {
            names.append("control")
        }
        if modifiers.contains(.shift) {
            names.append("shift")
        }
        if modifiers.contains(.command) {
            names.append("command")
        }
        if modifiers.contains(.option) {
            names.append("option")
        }
        return names.joined(separator: "+")
    }

    private nonisolated static func cgModifierDescription(_ flags: CGEventFlags) -> String {
        var names: [String] = []
        if flags.contains(.maskControl) {
            names.append("control")
        }
        if flags.contains(.maskShift) {
            names.append("shift")
        }
        if flags.contains(.maskCommand) {
            names.append("command")
        }
        if flags.contains(.maskAlternate) {
            names.append("option")
        }
        return names.isEmpty ? "none" : names.joined(separator: "+")
    }

    private nonisolated static func modifiersMatch(flags: CGEventFlags, modifiers: KeyboardShortcut.Modifiers) -> Bool {
        var expected: CGEventFlags = []
        if modifiers.contains(.command) {
            expected.insert(.maskCommand)
        }
        if modifiers.contains(.option) {
            expected.insert(.maskAlternate)
        }
        if modifiers.contains(.control) {
            expected.insert(.maskControl)
        }
        if modifiers.contains(.shift) {
            expected.insert(.maskShift)
        }
        let relevantFlags = flags.intersection([.maskCommand, .maskAlternate, .maskControl, .maskShift])
        return relevantFlags == expected
    }
}

private final class KeyboardEventTap {
    private let debugLogger: AppDebugLogger
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(debugLogger: AppDebugLogger) {
        self.debugLogger = debugLogger
    }

    func start() {
        stop()
        guard CGPreflightListenEventAccess() else {
            debugLogger.log("hotkey diagnostics cgevent tap not started; input monitoring not trusted")
            return
        }

        let eventsOfInterest =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventsOfInterest),
            callback: { _, type, event, userInfo in
                guard let userInfo else {
                    return Unmanaged.passUnretained(event)
                }
                let tap = Unmanaged<KeyboardEventTap>
                    .fromOpaque(userInfo)
                    .takeUnretainedValue()
                tap.log(event: event, type: type)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            debugLogger.log("hotkey diagnostics cgevent tap create failed")
            return
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
            debugLogger.log("hotkey diagnostics cgevent run loop source create failed")
            CFMachPortInvalidate(eventTap)
            return
        }

        self.eventTap = eventTap
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        debugLogger.log("hotkey diagnostics cgevent tap started")
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        runLoopSource = nil
        eventTap = nil
    }

    private func log(event: CGEvent, type: CGEventType) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        guard shouldLog(keyCode: keyCode, flags: flags, type: type) else {
            return
        }
        debugLogger.log(
            "hotkey diagnostics cgevent \(typeDescription(type)) keyCode=\(keyCode) modifiers=\(modifierDescription(flags))"
        )
    }

    private func shouldLog(keyCode: Int64, flags: CGEventFlags, type: CGEventType) -> Bool {
        if type == .flagsChanged {
            return true
        }
        let interestingKeys: Set<Int64> = [
            Int64(kVK_ANSI_S),
            Int64(kVK_ANSI_D),
            Int64(kVK_ANSI_V),
            Int64(kVK_Space)
        ]
        return interestingKeys.contains(keyCode)
            || flags.contains(.maskControl)
            || flags.contains(.maskShift)
            || flags.contains(.maskCommand)
            || flags.contains(.maskAlternate)
    }

    private func typeDescription(_ type: CGEventType) -> String {
        switch type {
        case .keyDown:
            "keyDown"
        case .keyUp:
            "keyUp"
        case .flagsChanged:
            "flagsChanged"
        default:
            "\(type.rawValue)"
        }
    }

    private func modifierDescription(_ flags: CGEventFlags) -> String {
        var names: [String] = []
        if flags.contains(.maskControl) {
            names.append("control")
        }
        if flags.contains(.maskShift) {
            names.append("shift")
        }
        if flags.contains(.maskCommand) {
            names.append("command")
        }
        if flags.contains(.maskAlternate) {
            names.append("option")
        }
        if flags.contains(.maskSecondaryFn) {
            names.append("fn")
        }
        return names.isEmpty ? "none" : names.joined(separator: "+")
    }
}

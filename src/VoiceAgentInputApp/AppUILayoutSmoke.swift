import AppKit
import VoiceAgentInputCore

@MainActor
enum AppUILayoutSmoke {
    static func run() -> Int32 {
        var failures: [String] = []
        let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build")
            .appendingPathComponent("ui-layout-smoke")

        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        } catch {
            print("ui layout smoke failed to create output directory: \(error)")
            return 1
        }

        let preview = PromptPreview(
            rawTranscript: String(repeating: "くらのコードでタイプスクリプトエラーを直して。", count: 10),
            correctedPrompt: String(repeating: "Claude Code で TypeScript エラーを直して。", count: 10),
            corrections: []
        )
        let previewController = PreviewWindowController(
            preview: preview,
            previewUseCase: PromptPreviewUseCase(entries: SeedDictionaries.codingAgentEntries)
        )
        failures.append(contentsOf: auditWindow(previewController.window, name: "preview"))
        renderWindow(previewController.window, name: "preview", outputDirectory: outputDirectory)

        let feedbackController = RecordingFeedbackWindowController(triggerMode: .toggleRecording) {}
        feedbackController.update(level: 0.45, hasDetectedVoice: true, elapsedSeconds: 127)
        failures.append(contentsOf: auditWindow(feedbackController.window, name: "recording-feedback"))
        renderWindow(feedbackController.window, name: "recording-feedback", outputDirectory: outputDirectory)

        let candidates = [
            CorrectionCandidate(
                rawPhrase: "とても長い誤認識候補のテキストがここに入って横幅を超えそうなケース",
                correctedPhrase: "VeryLongDeveloperTermNameUsedByCodingAgentsAndRepositoryVocabulary",
                confidence: 0.93,
                reason: "Likely voice misrecognition from a long Japanese-English mixed developer instruction.",
                suggestedScope: .user,
                dangerous: false
            ),
            CorrectionCandidate(
                rawPhrase: "rm dash rf",
                correctedPhrase: "rm -rf",
                confidence: 0.91,
                reason: "Dangerous command candidates must remain readable and unchecked.",
                suggestedScope: .user,
                dangerous: true
            )
        ]
        let accessory = CandidateApprovalDialogController().makeAccessoryView(candidates: candidates)
        failures.append(contentsOf: auditView(accessory.view, name: "candidate-approval"))
        renderView(
            accessory.view,
            size: NSSize(width: 560, height: accessory.view.fittingSize.height),
            name: "candidate-approval",
            outputDirectory: outputDirectory
        )

        let learningArguments = AppLayout.multilineTextView("--mode\nreview\n--json")
        let learningStack = AppLayout.formStack()
        learningStack.addArrangedSubview(AppLayout.formRow(label: "Reviewer command", view: AppLayout.textField("/usr/local/bin/local-reviewer")))
        learningStack.addArrangedSubview(AppLayout.formRow(label: "Arguments", view: learningArguments.scrollView))
        failures.append(contentsOf: auditView(learningStack, name: "learning-settings"))
        renderView(learningStack, size: NSSize(width: 560, height: 160), name: "learning-settings", outputDirectory: outputDirectory)

        let hotkeyStack = AppLayout.formStack()
        let keyPicker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 28), pullsDown: false)
        keyPicker.addItems(withTitles: ["Space", "A", "B", "C"])
        let triggerPicker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 28), pullsDown: false)
        triggerPicker.addItems(withTitles: ["Press and Hold", "Toggle Recording"])
        let modifierStack = NSStackView(views: [
            NSButton(checkboxWithTitle: "Control", target: nil, action: nil),
            NSButton(checkboxWithTitle: "Option", target: nil, action: nil),
            NSButton(checkboxWithTitle: "Shift", target: nil, action: nil),
            NSButton(checkboxWithTitle: "Command", target: nil, action: nil)
        ])
        modifierStack.orientation = .horizontal
        modifierStack.spacing = 8
        hotkeyStack.addArrangedSubview(AppLayout.formRow(label: "Key", view: keyPicker))
        hotkeyStack.addArrangedSubview(AppLayout.formRow(label: "Trigger", view: triggerPicker))
        hotkeyStack.addArrangedSubview(AppLayout.formRow(label: "Modifiers", view: modifierStack))
        failures.append(contentsOf: auditView(hotkeyStack, name: "hotkey-settings"))
        renderView(hotkeyStack, size: NSSize(width: 560, height: 132), name: "hotkey-settings", outputDirectory: outputDirectory)

        let recordingStack = AppLayout.formStack()
        recordingStack.addArrangedSubview(AppLayout.formRow(label: "Recording seconds", view: AppLayout.textField("8")))
        recordingStack.addArrangedSubview(AppLayout.formRow(label: "Speech locale", view: AppLayout.textField("ja-JP")))
        failures.append(contentsOf: auditView(recordingStack, name: "recording-settings"))
        renderView(recordingStack, size: NSSize(width: 560, height: 92), name: "recording-settings", outputDirectory: outputDirectory)

        let modePicker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 28), pullsDown: false)
        modePicker.addItems(withTitles: ["Quick Paste", "Learning Preview"])
        let modeStack = AppLayout.formStack()
        modeStack.addArrangedSubview(AppLayout.formRow(label: "Mode", view: modePicker))
        failures.append(contentsOf: auditView(modeStack, name: "voice-input-mode"))
        renderView(modeStack, size: NSSize(width: 560, height: 56), name: "voice-input-mode", outputDirectory: outputDirectory)

        let historyPopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 520, height: 28), pullsDown: false)
        historyPopup.addItem(withTitle: "Claude Code で TypeScript エラーを直して、pnpm test を実行して、失敗したログを要約")
        failures.append(contentsOf: auditView(historyPopup, name: "voice-input-history"))
        renderView(historyPopup, size: NSSize(width: 560, height: 48), name: "voice-input-history", outputDirectory: outputDirectory)

        let sourceStack = AppLayout.formStack()
        sourceStack.addArrangedSubview(NSButton(checkboxWithTitle: "Codex / Claude local sessions", target: nil, action: nil))
        sourceStack.addArrangedSubview(NSButton(checkboxWithTitle: "Git repository vocabulary", target: nil, action: nil))
        sourceStack.addArrangedSubview(AppLayout.wrappingLabel("/Users/tasuku/work/github.com/tasuku43/voice", maximumLines: 1))
        failures.append(contentsOf: auditView(sourceStack, name: "learning-sources"))
        renderView(sourceStack, size: NSSize(width: 560, height: 108), name: "learning-sources", outputDirectory: outputDirectory)

        if failures.isEmpty {
            print("ui layout smoke ok; rendered \(outputDirectory.path)")
            return 0
        }

        print("ui layout smoke failed:")
        for failure in failures {
            print("- \(failure)")
        }
        print("rendered \(outputDirectory.path)")
        return 1
    }

    private static func auditWindow(_ window: NSWindow?, name: String) -> [String] {
        guard let window else {
            return ["\(name): missing window"]
        }
        window.layoutIfNeeded()
        return auditView(window.contentView, name: name)
    }

    private static func auditView(_ view: NSView?, name: String) -> [String] {
        guard let view else {
            return ["\(name): missing view"]
        }
        view.layoutSubtreeIfNeeded()
        return audit(view, path: name)
    }

    private static func audit(_ view: NSView, path: String) -> [String] {
        var failures: [String] = []
        if String(describing: type(of: view)).hasPrefix("_NSText") {
            return failures
        }
        if !view.isHidden, view.superview != nil, view.frame.width <= 0 || view.frame.height <= 0 {
            failures.append("\(path): non-hidden view has empty frame \(view.frame)")
        }
        if view.hasAmbiguousLayout {
            failures.append("\(path): ambiguous Auto Layout")
        }
        if let label = view as? NSTextField, label.isEditable == false {
            let intrinsic = label.intrinsicContentSize
            let wraps = label.lineBreakMode == .byWordWrapping || label.maximumNumberOfLines != 1
            let truncates = label.lineBreakMode == .byTruncatingTail || label.lineBreakMode == .byTruncatingMiddle
            if intrinsic.width > label.frame.width + 1, !wraps, !truncates {
                failures.append("\(path): label may clip text '\(label.stringValue)' frame=\(label.frame) intrinsic=\(intrinsic)")
            }
        }
        for (index, subview) in view.subviews.enumerated() {
            failures.append(contentsOf: audit(subview, path: "\(path)/\(type(of: subview))[\(index)]"))
        }
        return failures
    }

    private static func renderWindow(_ window: NSWindow?, name: String, outputDirectory: URL) {
        guard let view = window?.contentView else {
            return
        }
        renderView(view, size: view.bounds.size, name: name, outputDirectory: outputDirectory, fill: true)
    }

    private static func renderView(
        _ view: NSView,
        size: NSSize,
        name: String,
        outputDirectory: URL,
        fill: Bool = false
    ) {
        let canvas = NSView(frame: NSRect(origin: .zero, size: size))
        canvas.wantsLayer = true
        canvas.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        view.removeFromSuperview()
        view.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(view)
        var constraints = [
            view.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
            view.topAnchor.constraint(equalTo: canvas.topAnchor)
        ]
        constraints.append(
            fill
                ? view.bottomAnchor.constraint(equalTo: canvas.bottomAnchor)
                : view.heightAnchor.constraint(lessThanOrEqualTo: canvas.heightAnchor)
        )
        NSLayoutConstraint.activate(constraints)
        canvas.layoutSubtreeIfNeeded()

        guard let bitmap = canvas.bitmapImageRepForCachingDisplay(in: canvas.bounds) else {
            return
        }
        canvas.cacheDisplay(in: canvas.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            return
        }
        try? data.write(to: outputDirectory.appendingPathComponent("\(name).png"), options: .atomic)
    }
}

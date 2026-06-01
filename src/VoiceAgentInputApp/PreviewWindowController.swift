import AppKit
import VoiceAgentInputCore

@MainActor
final class PreviewWindowController: NSWindowController {
    private let preview: PromptPreview
    private let previewUseCase: PromptPreviewUseCase
    private let editLearningUseCase: PromptEditLearningUseCase
    private let suggestedLearningScope: DictionaryScope
    private let candidateApprovalDialog = CandidateApprovalDialogController()
    private let correctedTextView = NSTextView()
    private let onConfirmedPaste: (ConfirmedPrompt) -> Void

    init(
        preview: PromptPreview,
        previewUseCase: PromptPreviewUseCase,
        editLearningUseCase: PromptEditLearningUseCase? = nil,
        suggestedLearningScope: DictionaryScope = .user,
        onConfirmedPaste: @escaping (ConfirmedPrompt) -> Void = { _ in }
    ) {
        self.preview = preview
        self.previewUseCase = previewUseCase
        self.editLearningUseCase = editLearningUseCase ?? PromptEditLearningUseCase(previewUseCase: previewUseCase)
        self.suggestedLearningScope = suggestedLearningScope
        self.onConfirmedPaste = onConfirmedPaste

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
        let rawText = textBox(preview.rawTranscript, editable: false, highlights: rawHighlights())
        let correctedLabel = NSTextField(labelWithString: "Corrected prompt")
        let correctedScrollView = textBox(preview.correctedPrompt, editable: true, highlights: correctedHighlights())

        if let textView = correctedScrollView.documentView as? NSTextView {
            correctedTextView.textStorage?.setAttributedString(textView.attributedString())
            correctedScrollView.documentView = correctedTextView
            correctedTextView.isEditable = true
            correctedTextView.font = NSFont.systemFont(ofSize: 14)
            correctedTextView.isRichText = false
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

    private func textBox(_ string: String, editable: Bool, highlights: [String]) -> NSScrollView {
        let textView = NSTextView()
        textView.textStorage?.setAttributedString(highlightedString(string, highlights: highlights))
        textView.isEditable = editable
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.isRichText = false

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        scrollView.borderType = .bezelBorder
        return scrollView
    }

    private func rawHighlights() -> [String] {
        preview.corrections.map(\.original)
    }

    private func correctedHighlights() -> [String] {
        preview.corrections.map { correction in
            correction.replacement.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func highlightedString(_ string: String, highlights: [String]) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: string,
            attributes: [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
        )
        let highlightColor = NSColor.systemYellow.withAlphaComponent(0.24)

        for highlight in highlights where !highlight.isEmpty {
            var searchRange = string.startIndex..<string.endIndex
            while let range = string.range(of: highlight, options: [], range: searchRange) {
                attributed.addAttributes(
                    [
                        .backgroundColor: highlightColor,
                        .toolTip: "Dictionary correction"
                    ],
                    range: NSRange(range, in: string)
                )
                searchRange = range.upperBound..<string.endIndex
            }
        }

        return attributed
    }

    @objc private func confirm() {
        Task { @MainActor in
            do {
                let confirmed = try await editLearningUseCase.confirm(
                    preview: preview,
                    finalEditedPrompt: correctedTextView.string,
                    suggestedScope: suggestedLearningScope
                )
                try insertConfirmedPrompt(confirmed)
                onConfirmedPaste(confirmed)
                close()
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    private func insertConfirmedPrompt(_ confirmed: ConfirmedPrompt) throws {
        do {
                let insertion = PromptInsertionUseCase(insertionController: AccessibilityTextInsertionController())
                try insertion.insert(confirmed, explicitConfirmation: true)
                try candidateApprovalDialog.approveCandidatesIfRequested(confirmed.candidates)
        } catch AccessibilityTextInsertionError.accessibilityPermissionRequired {
            try PromptInsertionUseCase(
                insertionController: PasteboardTextInsertionController()
            ).insert(confirmed, explicitConfirmation: true)
            showAccessibilityFallbackAlert()
            try candidateApprovalDialog.approveCandidatesIfRequested(confirmed.candidates)
        }
    }

    private func showAccessibilityFallbackAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Prompt copied"
        alert.informativeText = "Enable Accessibility access for Voice Agent Input in System Settings to paste automatically. For now, press Command-V in the target app."
        alert.runModal()
    }

    @objc private func cancel() {
        close()
    }
}

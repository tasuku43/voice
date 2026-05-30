import AppKit
import VoiceAgentInputCore

@MainActor
final class PreviewWindowController: NSWindowController {
    private let preview: PromptPreview
    private let previewUseCase: PromptPreviewUseCase
    private let candidateApprovalDialog = CandidateApprovalDialogController()
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
            try candidateApprovalDialog.approveCandidatesIfRequested(confirmed.candidates)
            close()
        } catch AccessibilityTextInsertionError.accessibilityPermissionRequired {
            do {
                try PromptInsertionUseCase(
                    insertionController: PasteboardTextInsertionController()
                ).insert(confirmed, explicitConfirmation: true)
                showAccessibilityFallbackAlert()
                try candidateApprovalDialog.approveCandidatesIfRequested(confirmed.candidates)
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

    @objc private func cancel() {
        close()
    }
}

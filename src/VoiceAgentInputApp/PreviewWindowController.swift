import AppKit
import VoiceAgentInputCore

@MainActor
final class PreviewWindowController: NSWindowController {
    private let fallback: PreviewFallback
    private let fallbackUseCase: PreviewFallbackUseCase
    private let correctedTextView = NSTextView()
    private let onPromptInserted: (PromptInsertion) -> Void

    init(
        fallback: PreviewFallback,
        fallbackUseCase: PreviewFallbackUseCase,
        onPromptInserted: @escaping (PromptInsertion) -> Void = { _ in }
    ) {
        self.fallback = fallback
        self.fallbackUseCase = fallbackUseCase
        self.onPromptInserted = onPromptInserted

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
        container.translatesAutoresizingMaskIntoConstraints = false

        let rawLabel = NSTextField(labelWithString: "Raw transcript")
        let rawText = textBox(fallback.rawTranscript, editable: false, highlights: rawHighlights())
        let correctedLabel = NSTextField(labelWithString: "Corrected prompt")
        let correctedScrollView = textBox(fallback.correctedPrompt, editable: true, highlights: correctedHighlights())

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

        let root = NSView()
        root.addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            container.topAnchor.constraint(equalTo: root.topAnchor),
            container.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        return root
    }

    private func textBox(_ string: String, editable: Bool, highlights: [String]) -> NSScrollView {
        let textView = NSTextView()
        textView.textStorage?.setAttributedString(highlightedString(string, highlights: highlights))
        textView.isEditable = editable
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.isRichText = false
        textView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        scrollView.borderType = .bezelBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }

    private func rawHighlights() -> [String] {
        fallback.corrections.map(\.original)
    }

    private func correctedHighlights() -> [String] {
        fallback.corrections.map { correction in
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
                let insertion = fallbackUseCase.makeInsertion(
                    fallback: fallback,
                    finalEditedPrompt: correctedTextView.string
                )
                try insertPrompt(insertion)
                onPromptInserted(insertion)
                close()
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    private func insertPrompt(_ prompt: PromptInsertion) throws {
        do {
            let insertion = PromptInsertionUseCase(insertionController: AccessibilityTextInsertionController())
            try insertion.insert(prompt, afterUserAction: true)
        } catch AccessibilityTextInsertionError.accessibilityPermissionRequired {
            try PromptInsertionUseCase(
                insertionController: PasteboardTextInsertionController()
            ).insert(prompt, afterUserAction: true)
            showAccessibilityFallbackAlert()
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

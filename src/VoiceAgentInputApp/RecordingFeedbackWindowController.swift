import AppKit
import ApplicationServices
import VoiceAgentInputCore

@MainActor
final class RecordingFeedbackWindowController: NSWindowController {
    private let titleLabel = NSTextField(labelWithString: "Getting ready")
    private let guidanceLabel = NSTextField(labelWithString: "Release shortcut to paste")
    private let elapsedLabel = NSTextField(labelWithString: "0:00")
    private let statusDotView = RecordingStatusDotView()
    private let waveformView = RecordingWaveformView()
    private let stopAction: () -> Void
    private let presentationUseCase = RecordingFeedbackPresentationUseCase()
    private var lastAnchorRefresh = Date.distantPast

    init(stopAction: @escaping () -> Void) {
        self.stopAction = stopAction
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 376, height: 68),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true

        super.init(window: window)
        window.contentView = buildContentView()
        positionNearFocusedInput()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func update(level: Float?, hasDetectedVoice: Bool, elapsedSeconds: TimeInterval) {
        let presentation = presentationUseCase.presentation(
            level: level,
            hasDetectedVoice: hasDetectedVoice,
            elapsedSeconds: elapsedSeconds
        )
        titleLabel.stringValue = presentation.title
        guidanceLabel.stringValue = presentation.guidance
        elapsedLabel.stringValue = presentation.elapsedText
        elapsedLabel.toolTip = presentation.accessibilityLabel
        window?.contentView?.toolTip = presentation.accessibilityLabel
        window?.contentView?.setAccessibilityLabel(presentation.accessibilityLabel)
        statusDotView.phase = presentation.phase
        waveformView.phase = presentation.phase
        waveformView.levels = presentation.meterLevels.map { CGFloat($0) }
        refreshAnchorIfNeeded()
    }

    private func buildContentView() -> NSView {
        let container = RecordingFeedbackContainerView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let contentStack = NSStackView()
        contentStack.orientation = .horizontal
        contentStack.alignment = .centerY
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        statusDotView.translatesAutoresizingMaskIntoConstraints = false
        statusDotView.widthAnchor.constraint(equalToConstant: 12).isActive = true
        statusDotView.heightAnchor.constraint(equalToConstant: 12).isActive = true

        waveformView.translatesAutoresizingMaskIntoConstraints = false
        waveformView.widthAnchor.constraint(equalToConstant: 76).isActive = true
        waveformView.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 1
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 178).isActive = true
        textStack.heightAnchor.constraint(equalToConstant: 34).isActive = true

        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true

        guidanceLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        guidanceLabel.textColor = .secondaryLabelColor
        guidanceLabel.lineBreakMode = .byTruncatingTail
        guidanceLabel.translatesAutoresizingMaskIntoConstraints = false
        guidanceLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        guidanceLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(guidanceLabel)
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalTo: textStack.widthAnchor),
            guidanceLabel.widthAnchor.constraint(equalTo: textStack.widthAnchor)
        ])

        elapsedLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        elapsedLabel.alignment = .center
        elapsedLabel.textColor = .secondaryLabelColor
        elapsedLabel.wantsLayer = true
        elapsedLabel.layer?.cornerRadius = 7
        elapsedLabel.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.55).cgColor
        elapsedLabel.translatesAutoresizingMaskIntoConstraints = false
        elapsedLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 38).isActive = true
        elapsedLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let stopButton = RecordingStopButton(target: self, action: #selector(stop))
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
        stopButton.heightAnchor.constraint(equalToConstant: 28).isActive = true

        contentStack.addArrangedSubview(statusDotView)
        contentStack.addArrangedSubview(waveformView)
        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(elapsedLabel)
        contentStack.addArrangedSubview(stopButton)
        container.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 13),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            contentStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func refreshAnchorIfNeeded() {
        guard Date().timeIntervalSince(lastAnchorRefresh) > 0.35 else {
            return
        }
        lastAnchorRefresh = Date()
        positionNearFocusedInput()
    }

    private func positionNearFocusedInput() {
        guard let window else {
            return
        }
        let screen = Self.screen(for: window) ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            return
        }

        if let focusedAnchor = Self.focusedInputAnchor() {
            let origin: NSPoint
            switch focusedAnchor.kind {
            case .caret:
                origin = Self.originNextToCaret(
                    focusedAnchor.frame,
                    windowSize: window.frame.size,
                    visibleFrame: visibleFrame
                )
            case .focusedElement:
                origin = Self.originAboveFocusedElement(
                    focusedAnchor.frame,
                    windowSize: window.frame.size,
                    visibleFrame: visibleFrame
                )
            }
            window.setFrameOrigin(origin)
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let origin = NSPoint(
            x: min(max(mouseLocation.x + 14, visibleFrame.minX + 8), visibleFrame.maxX - window.frame.width - 8),
            y: min(max(mouseLocation.y + 14, visibleFrame.minY + 8), visibleFrame.maxY - window.frame.height - 8)
        )
        window.setFrameOrigin(origin)
    }

    private static func screen(for window: NSWindow) -> NSScreen? {
        if let screen = window.screen {
            return screen
        }
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouseLocation) }
    }

    private static func originNextToCaret(
        _ caretFrame: CGRect,
        windowSize: CGSize,
        visibleFrame: CGRect
    ) -> NSPoint {
        let gap: CGFloat = 10
        let rightX = caretFrame.maxX + gap
        let leftX = caretFrame.minX - windowSize.width - gap
        let unclampedX = rightX + windowSize.width <= visibleFrame.maxX - 8 ? rightX : leftX
        return NSPoint(
            x: min(max(unclampedX, visibleFrame.minX + 8), visibleFrame.maxX - windowSize.width - 8),
            y: min(
                max(caretFrame.midY - windowSize.height / 2, visibleFrame.minY + 8),
                visibleFrame.maxY - windowSize.height - 8
            )
        )
    }

    private static func originAboveFocusedElement(
        _ elementFrame: CGRect,
        windowSize: CGSize,
        visibleFrame: CGRect
    ) -> NSPoint {
        let aboveY = elementFrame.maxY + 8
        let belowY = elementFrame.minY - windowSize.height - 8
        let unclampedY = aboveY + windowSize.height <= visibleFrame.maxY - 8 ? aboveY : belowY
        return NSPoint(
            x: min(max(elementFrame.minX, visibleFrame.minX + 8), visibleFrame.maxX - windowSize.width - 8),
            y: min(max(unclampedY, visibleFrame.minY + 8), visibleFrame.maxY - windowSize.height - 8)
        )
    }

    private static func focusedInputAnchor() -> RecordingFeedbackAnchor? {
        guard let element = focusedElement() else {
            return nil
        }
        if let caretFrame = selectedTextRangeFrame(in: element) {
            return RecordingFeedbackAnchor(frame: caretFrame, kind: .caret)
        }
        if let elementFrame = elementFrame(element) {
            return RecordingFeedbackAnchor(frame: elementFrame, kind: .focusedElement)
        }
        return nil
    }

    private static func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        ) == .success else {
            return nil
        }

        guard let element = focusedValue else {
            return nil
        }

        return (element as! AXUIElement)
    }

    private static func selectedTextRangeFrame(in element: AXUIElement) -> CGRect? {
        var rangeValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &rangeValue
        ) == .success,
            let rangeValue
        else {
            return nil
        }

        var boundsValue: AnyObject?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue,
            &boundsValue
        ) == .success,
            let boundsValue
        else {
            return nil
        }

        let boundsAXValue = boundsValue as! AXValue
        var bounds = CGRect.zero
        guard AXValueGetValue(boundsAXValue, .cgRect, &bounds),
              !bounds.isNull,
              bounds.height > 0
        else {
            return nil
        }
        return bounds
    }

    private static func elementFrame(_ element: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        ) == .success,
            AXUIElementCopyAttributeValue(
                element,
                kAXSizeAttribute as CFString,
                &sizeValue
            ) == .success,
            let positionAXValue = positionValue,
            let sizeAXValue = sizeValue
        else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionAXValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeAXValue as! AXValue, .cgSize, &size)
        return CGRect(origin: position, size: size)
    }

    @objc private func stop() {
        stopAction()
    }
}

private struct RecordingFeedbackAnchor {
    var frame: CGRect
    var kind: Kind

    enum Kind {
        case caret
        case focusedElement
    }
}

private final class RecordingFeedbackContainerView: NSVisualEffectView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 18
        layer?.masksToBounds = true
        setAccessibilityRole(.group)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func updateLayer() {
        super.updateLayer()
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.45).cgColor
    }
}

private final class RecordingStatusDotView: NSView {
    var phase: RecordingFeedbackPhase = .connecting {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let color: NSColor
        switch phase {
        case .connecting:
            color = .systemOrange
        case .listening:
            color = .systemGreen
        case .quiet:
            color = .systemYellow
        }

        color.withAlphaComponent(0.18).setFill()
        NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1)).fill()
        color.setFill()
        NSBezierPath(ovalIn: bounds.insetBy(dx: 3.5, dy: 3.5)).fill()
    }
}

private final class RecordingWaveformView: NSView {
    var phase: RecordingFeedbackPhase = .connecting {
        didSet { needsDisplay = true }
    }
    var levels: [CGFloat] = Array(repeating: 0.18, count: 10) {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard !levels.isEmpty else {
            return
        }

        let color: NSColor
        switch phase {
        case .connecting:
            color = .tertiaryLabelColor
        case .listening:
            color = .controlAccentColor
        case .quiet:
            color = .secondaryLabelColor
        }

        let barWidth: CGFloat = 4
        let spacing = (bounds.width - barWidth * CGFloat(levels.count)) / CGFloat(max(1, levels.count - 1))
        for (index, rawLevel) in levels.enumerated() {
            let level = min(max(rawLevel, 0.08), 1)
            let height = max(6, bounds.height * level)
            let x = CGFloat(index) * (barWidth + spacing)
            let rect = NSRect(
                x: x,
                y: bounds.midY - height / 2,
                width: barWidth,
                height: height
            )
            color.withAlphaComponent(0.36 + level * 0.52).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2).fill()
        }
    }
}

private final class RecordingStopButton: NSButton {
    init(target: AnyObject?, action: Selector) {
        super.init(frame: .zero)
        title = ""
        self.target = target
        self.action = action
        bezelStyle = .regularSquare
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 14
        toolTip = "Stop voice input and paste"
        setAccessibilityLabel("Stop voice input and paste")
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(isHighlighted ? 0.22 : 0.14).cgColor
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.systemRed.setFill()
        let side: CGFloat = 9
        let rect = NSRect(
            x: bounds.midX - side / 2,
            y: bounds.midY - side / 2,
            width: side,
            height: side
        )
        NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2).fill()
    }
}

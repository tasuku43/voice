import AppKit
import ApplicationServices

@MainActor
final class RecordingFeedbackWindowController: NSWindowController {
    private let statusLabel = NSTextField(labelWithString: "Connecting")
    private let statusView = RecordingStatusView()
    private let stopAction: () -> Void

    init(stopAction: @escaping () -> Void) {
        self.stopAction = stopAction
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 132, height: 34),
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

    func update(level: Float?, hasDetectedVoice: Bool) {
        let state = RecordingFeedbackState(level: level, hasDetectedVoice: hasDetectedVoice)
        statusLabel.stringValue = state.displayTitle
        statusLabel.toolTip = state.accessibilityTitle
        window?.contentView?.toolTip = state.accessibilityTitle
        window?.contentView?.setAccessibilityLabel(state.accessibilityTitle)
        statusView.state = state
    }

    private func buildContentView() -> NSView {
        let container = NSVisualEffectView()
        container.material = .hudWindow
        container.blendingMode = .behindWindow
        container.state = .active
        container.wantsLayer = true
        container.layer?.cornerRadius = 17
        container.layer?.masksToBounds = true

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        statusView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let stopButton = NSButton(title: "", target: self, action: #selector(stop))
        stopButton.bezelStyle = .circular
        stopButton.controlSize = .mini
        stopButton.contentTintColor = .systemRed
        stopButton.toolTip = "Stop voice input"
        stopButton.setAccessibilityLabel("Stop voice input")
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.widthAnchor.constraint(equalToConstant: 18).isActive = true
        stopButton.heightAnchor.constraint(equalToConstant: 18).isActive = true

        stack.addArrangedSubview(statusView)
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(stopButton)
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func positionNearFocusedInput() {
        guard let window, let screen = NSScreen.main else {
            return
        }
        if let focusedAnchor = Self.focusedInputAnchor() {
            let visibleFrame = screen.visibleFrame
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
        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: min(max(mouseLocation.x + 12, visibleFrame.minX + 8), visibleFrame.maxX - window.frame.width - 8),
            y: min(max(mouseLocation.y + 12, visibleFrame.minY + 8), visibleFrame.maxY - window.frame.height - 8)
        )
        window.setFrameOrigin(origin)
    }

    private static func originNextToCaret(
        _ caretFrame: CGRect,
        windowSize: CGSize,
        visibleFrame: CGRect
    ) -> NSPoint {
        let gap: CGFloat = 4
        let rightX = caretFrame.maxX + gap
        let leftX = caretFrame.minX - windowSize.width - gap
        let unclampedX = rightX + windowSize.width <= visibleFrame.maxX - 6 ? rightX : leftX
        return NSPoint(
            x: min(max(unclampedX, visibleFrame.minX + 6), visibleFrame.maxX - windowSize.width - 6),
            y: min(
                max(caretFrame.midY - windowSize.height / 2, visibleFrame.minY + 6),
                visibleFrame.maxY - windowSize.height - 6
            )
        )
    }

    private static func originAboveFocusedElement(
        _ elementFrame: CGRect,
        windowSize: CGSize,
        visibleFrame: CGRect
    ) -> NSPoint {
        NSPoint(
            x: min(max(elementFrame.minX, visibleFrame.minX + 8), visibleFrame.maxX - windowSize.width - 8),
            y: min(max(elementFrame.maxY + 6, visibleFrame.minY + 8), visibleFrame.maxY - windowSize.height - 8)
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

private enum RecordingFeedbackState: Equatable {
    case connecting
    case listening(level: CGFloat)
    case paused

    init(level: Float?, hasDetectedVoice: Bool) {
        guard let level else {
            self = .connecting
            return
        }
        if level > 0.08 {
            self = .listening(level: CGFloat(level))
        } else if hasDetectedVoice {
            self = .paused
        } else {
            self = .listening(level: CGFloat(level))
        }
    }

    var title: String {
        switch self {
        case .connecting:
            "Connecting microphone..."
        case .listening:
            "Listening"
        case .paused:
            "Input paused"
        }
    }

    var displayTitle: String {
        switch self {
        case .connecting:
            "Connecting"
        case .listening:
            "Listening"
        case .paused:
            "Paused"
        }
    }

    var accessibilityTitle: String {
        title
    }
}

private final class RecordingStatusView: NSView {
    var state: RecordingFeedbackState = .connecting {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let iconRect = bounds.insetBy(dx: 4, dy: 2)
        let strokeColor: NSColor
        let fillColor: NSColor
        switch state {
        case .connecting:
            strokeColor = .tertiaryLabelColor
            fillColor = .clear
        case let .listening(level):
            strokeColor = .systemBlue
            fillColor = level > 0.08 ? NSColor.systemBlue.withAlphaComponent(0.18) : .clear
        case .paused:
            strokeColor = .secondaryLabelColor
            fillColor = .quaternaryLabelColor
        }

        if case .connecting = state {
            drawWaitingDots(in: iconRect, color: strokeColor)
            return
        }

        fillColor.setFill()
        strokeColor.setStroke()
        let micBody = NSBezierPath(
            roundedRect: NSRect(x: iconRect.midX - 3.5, y: iconRect.midY - 5, width: 7, height: 11),
            xRadius: 3.5,
            yRadius: 3.5
        )
        micBody.lineWidth = 1.5
        micBody.fill()
        micBody.stroke()

        let stem = NSBezierPath()
        stem.lineWidth = 1.5
        stem.move(to: NSPoint(x: iconRect.midX, y: iconRect.minY + 2))
        stem.line(to: NSPoint(x: iconRect.midX, y: iconRect.midY - 6))
        stem.move(to: NSPoint(x: iconRect.midX - 4, y: iconRect.minY + 2))
        stem.line(to: NSPoint(x: iconRect.midX + 4, y: iconRect.minY + 2))
        stem.stroke()

        if case .paused = state {
            strokeColor.setStroke()
            let pause = NSBezierPath()
            pause.lineWidth = 1.7
            pause.move(to: NSPoint(x: iconRect.maxX - 4.5, y: iconRect.midY - 4))
            pause.line(to: NSPoint(x: iconRect.maxX - 4.5, y: iconRect.midY + 4))
            pause.move(to: NSPoint(x: iconRect.maxX - 1.5, y: iconRect.midY - 4))
            pause.line(to: NSPoint(x: iconRect.maxX - 1.5, y: iconRect.midY + 4))
            pause.stroke()
        }
    }

    private func drawWaitingDots(in rect: NSRect, color: NSColor) {
        let dotSize: CGFloat = 3.5
        let spacing: CGFloat = 3.5
        let totalWidth = dotSize * 3 + spacing * 2
        let startX = rect.midX - totalWidth / 2
        for index in 0..<3 {
            color.withAlphaComponent(0.35 + CGFloat(index) * 0.22).setFill()
            let dotRect = NSRect(
                x: startX + CGFloat(index) * (dotSize + spacing),
                y: rect.midY - dotSize / 2,
                width: dotSize,
                height: dotSize
            )
            NSBezierPath(ovalIn: dotRect).fill()
        }
    }
}

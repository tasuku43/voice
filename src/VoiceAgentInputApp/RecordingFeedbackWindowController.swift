import AppKit

@MainActor
final class RecordingFeedbackWindowController: NSWindowController {
    private let statusLabel = NSTextField(labelWithString: "Connecting microphone...")
    private let levelView = InputLevelView()
    private let stopAction: () -> Void

    init(stopAction: @escaping () -> Void) {
        self.stopAction = stopAction
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 310, height: 48),
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
        positionNearMenuBar()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func update(level: Float?, hasDetectedVoice: Bool) {
        statusLabel.stringValue = hasDetectedVoice ? "Listening" : "Connecting microphone..."
        levelView.level = CGFloat(level ?? 0)
        levelView.isWaitingForSignal = !hasDetectedVoice
    }

    private func buildContentView() -> NSView {
        let container = NSVisualEffectView()
        container.material = .hudWindow
        container.blendingMode = .behindWindow
        container.state = .active
        container.wantsLayer = true
        container.layer?.cornerRadius = 22
        container.layer?.masksToBounds = true

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = NSButton(title: "×", target: self, action: #selector(stop))
        closeButton.bezelStyle = .circular
        closeButton.controlSize = .small

        statusLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor

        levelView.translatesAutoresizingMaskIntoConstraints = false
        levelView.widthAnchor.constraint(equalToConstant: 96).isActive = true
        levelView.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let stopButton = NSButton(title: "■", target: self, action: #selector(stop))
        stopButton.bezelStyle = .circular
        stopButton.controlSize = .small
        stopButton.contentTintColor = .systemRed

        stack.addArrangedSubview(closeButton)
        stack.addArrangedSubview(levelView)
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(stopButton)
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func positionNearMenuBar() {
        guard let window, let screen = NSScreen.main else {
            return
        }
        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.midX - window.frame.width / 2,
            y: visibleFrame.maxY - window.frame.height - 12
        )
        window.setFrameOrigin(origin)
    }

    @objc private func stop() {
        stopAction()
    }
}

private final class InputLevelView: NSView {
    var level: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    var isWaitingForSignal = true {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let barCount = 12
        let gap: CGFloat = 3
        let barWidth = (bounds.width - CGFloat(barCount - 1) * gap) / CGFloat(barCount)
        let activeBars = Int(ceil(level * CGFloat(barCount)))

        for index in 0..<barCount {
            let heightRatio = CGFloat((index % 5) + 1) / 5
            let height = max(3, bounds.height * heightRatio * max(0.25, level))
            let rect = NSRect(
                x: CGFloat(index) * (barWidth + gap),
                y: (bounds.height - height) / 2,
                width: barWidth,
                height: height
            )
            let color: NSColor
            if isWaitingForSignal {
                color = .tertiaryLabelColor
            } else {
                color = index < activeBars ? .systemBlue : .quaternaryLabelColor
            }
            color.setFill()
            NSBezierPath(roundedRect: rect, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
        }
    }
}

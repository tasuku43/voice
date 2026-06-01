import AppKit

@MainActor
final class PushToTalkWindowController: NSWindowController {
    private let buttonView: PushToTalkButtonView

    init(startAction: @escaping () -> Void, stopAction: @escaping () -> Void) {
        buttonView = PushToTalkButtonView(startAction: startAction, stopAction: stopAction)
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 104, height: 36),
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
        window.contentView = buttonView
        positionNearBottomRight()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setRecording(_ recording: Bool) {
        buttonView.isRecording = recording
    }

    private func positionNearBottomRight() {
        guard let window, let screen = NSScreen.main else {
            return
        }
        let visibleFrame = screen.visibleFrame
        window.setFrameOrigin(NSPoint(
            x: visibleFrame.maxX - window.frame.width - 18,
            y: visibleFrame.minY + 18
        ))
    }
}

private final class PushToTalkButtonView: NSView {
    var isRecording = false {
        didSet { needsDisplay = true }
    }

    private let startAction: () -> Void
    private let stopAction: () -> Void

    init(startAction: @escaping () -> Void, stopAction: @escaping () -> Void) {
        self.startAction = startAction
        self.stopAction = stopAction
        super.init(frame: NSRect(x: 0, y: 0, width: 104, height: 36))
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func mouseDown(with event: NSEvent) {
        guard !isRecording else {
            return
        }
        isRecording = true
        startAction()
    }

    override func mouseUp(with event: NSEvent) {
        guard isRecording else {
            return
        }
        isRecording = false
        stopAction()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let background = isRecording
            ? NSColor.systemRed.withAlphaComponent(0.92)
            : NSColor.controlAccentColor.withAlphaComponent(0.92)
        background.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 18, yRadius: 18).fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let title = isRecording ? "Release" : "Hold"
        let attributed = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraph
            ]
        )
        let textRect = NSRect(x: 0, y: (bounds.height - 16) / 2, width: bounds.width, height: 18)
        attributed.draw(in: textRect)
    }
}

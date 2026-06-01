import AppKit

@MainActor
enum AppLayout {
    static let accessoryWidth: CGFloat = 520
    static let formLabelWidth: CGFloat = 148
    static let formControlWidth: CGFloat = 300

    static func formStack(width: CGFloat = accessoryWidth) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(greaterThanOrEqualToConstant: width).isActive = true
        return stack
    }

    static func formRow(label: String, view: NSView, controlWidth: CGFloat = formControlWidth) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false

        let labelField = NSTextField(labelWithString: label)
        labelField.alignment = .right
        labelField.lineBreakMode = .byTruncatingTail
        labelField.translatesAutoresizingMaskIntoConstraints = false

        view.translatesAutoresizingMaskIntoConstraints = false

        row.addArrangedSubview(labelField)
        row.addArrangedSubview(view)

        NSLayoutConstraint.activate([
            labelField.widthAnchor.constraint(equalToConstant: formLabelWidth),
            view.widthAnchor.constraint(greaterThanOrEqualToConstant: controlWidth)
        ])
        return row
    }

    static func textField(_ value: String, width: CGFloat = formControlWidth) -> NSTextField {
        let field = NSTextField(string: value)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(greaterThanOrEqualToConstant: width).isActive = true
        return field
    }

    static func wrappingLabel(
        _ text: String,
        width: CGFloat = accessoryWidth,
        maximumLines: Int = 0
    ) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = maximumLines
        label.preferredMaxLayoutWidth = width
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(lessThanOrEqualToConstant: width).isActive = true
        return label
    }

    static func multilineTextView(
        _ value: String,
        width: CGFloat = formControlWidth,
        height: CGFloat = 88
    ) -> (scrollView: NSScrollView, textView: NSTextView) {
        let textView = NSTextView()
        textView.string = value
        textView.isEditable = true
        textView.isRichText = false
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = textView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: width),
            scrollView.heightAnchor.constraint(equalToConstant: height)
        ])
        return (scrollView, textView)
    }
}

import AppKit
import Foundation

public struct PasteboardTextInsertionController: TextInsertionController {
    public var pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func insert(_ request: TextInsertionRequest) throws {
        pasteboard.clearContents()
        pasteboard.setString(request.text, forType: .string)
    }
}

import Foundation

public struct TextInsertionRequest: Equatable, Sendable {
    public var text: String

    public init(text: String) {
        self.text = text
    }
}

public protocol TextInsertionController {
    func insert(_ request: TextInsertionRequest) throws
}

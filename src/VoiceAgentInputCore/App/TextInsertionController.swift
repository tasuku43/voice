import Foundation

public struct TextInsertionRequest: Equatable, Sendable {
    public var text: String
    public var submitAutomatically: Bool

    public init(text: String, submitAutomatically: Bool = false) {
        self.text = text
        self.submitAutomatically = submitAutomatically
    }
}

public protocol TextInsertionController {
    func insert(_ request: TextInsertionRequest) throws
}

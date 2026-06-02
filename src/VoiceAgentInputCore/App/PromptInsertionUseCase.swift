import Foundation

public enum PromptInsertionError: Error, Equatable {
    case userActionRequired
}

public struct PromptInsertion: Codable, Equatable, Sendable {
    public var text: String

    public init(text: String) {
        self.text = text
    }
}

public struct PromptInsertionUseCase {
    public var insertionController: any TextInsertionController

    public init(insertionController: any TextInsertionController) {
        self.insertionController = insertionController
    }

    public func insert(_ prompt: PromptInsertion, afterUserAction: Bool) throws {
        guard afterUserAction else {
            throw PromptInsertionError.userActionRequired
        }

        try insertionController.insert(
            TextInsertionRequest(text: prompt.text)
        )
    }
}

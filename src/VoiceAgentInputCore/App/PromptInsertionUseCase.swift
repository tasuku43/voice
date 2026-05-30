import Foundation

public enum PromptInsertionError: Error, Equatable {
    case explicitConfirmationRequired
    case automaticSubmitRejected
}

public struct PromptInsertionUseCase {
    public var insertionController: any TextInsertionController

    public init(insertionController: any TextInsertionController) {
        self.insertionController = insertionController
    }

    public func insert(_ confirmedPrompt: ConfirmedPrompt, explicitConfirmation: Bool) throws {
        guard explicitConfirmation else {
            throw PromptInsertionError.explicitConfirmationRequired
        }
        guard !confirmedPrompt.shouldSubmitAutomatically else {
            throw PromptInsertionError.automaticSubmitRejected
        }

        try insertionController.insert(
            TextInsertionRequest(
                text: confirmedPrompt.promptToInsert,
                submitAutomatically: false
            )
        )
    }
}

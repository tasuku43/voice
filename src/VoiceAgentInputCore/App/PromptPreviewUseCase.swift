import Foundation

public struct PromptPreview: Codable, Equatable, Sendable {
    public var rawTranscript: String
    public var correctedPrompt: String
    public var corrections: [AppliedCorrection]
    public var requiresExplicitConfirmation: Bool

    public init(
        rawTranscript: String,
        correctedPrompt: String,
        corrections: [AppliedCorrection],
        requiresExplicitConfirmation: Bool = true
    ) {
        self.rawTranscript = rawTranscript
        self.correctedPrompt = correctedPrompt
        self.corrections = corrections
        self.requiresExplicitConfirmation = requiresExplicitConfirmation
    }
}

public struct ConfirmedPrompt: Codable, Equatable, Sendable {
    public var promptToInsert: String
    public var shouldSubmitAutomatically: Bool

    public init(
        promptToInsert: String,
        shouldSubmitAutomatically: Bool = false
    ) {
        self.promptToInsert = promptToInsert
        self.shouldSubmitAutomatically = shouldSubmitAutomatically
    }
}

public struct PromptPreviewUseCase: Sendable {
    public var normalizationUseCase: PromptNormalizationUseCase

    public init(normalizationUseCase: PromptNormalizationUseCase) {
        self.normalizationUseCase = normalizationUseCase
    }

    public init(entries: [DictionaryEntry]) {
        self.normalizationUseCase = PromptNormalizationUseCase(entries: entries)
    }

    public func preview(rawTranscript: String) -> PromptPreview {
        let result = normalizationUseCase.normalize(rawText: rawTranscript)
        return PromptPreview(
            rawTranscript: result.rawText,
            correctedPrompt: result.correctedText,
            corrections: result.corrections
        )
    }

    public func confirm(preview: PromptPreview, finalEditedPrompt: String? = nil) -> ConfirmedPrompt {
        let promptToInsert = finalEditedPrompt ?? preview.correctedPrompt
        return ConfirmedPrompt(promptToInsert: promptToInsert)
    }
}

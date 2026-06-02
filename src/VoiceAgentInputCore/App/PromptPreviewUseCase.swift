import Foundation

public struct PromptPreview: Codable, Equatable, Sendable {
    public var rawTranscript: String
    public var correctedPrompt: String
    public var corrections: [AppliedCorrection]

    public init(
        rawTranscript: String,
        correctedPrompt: String,
        corrections: [AppliedCorrection]
    ) {
        self.rawTranscript = rawTranscript
        self.correctedPrompt = correctedPrompt
        self.corrections = corrections
    }
}

public struct PromptInsertion: Codable, Equatable, Sendable {
    public var text: String

    public init(text: String) {
        self.text = text
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

    public func makeInsertion(preview: PromptPreview, finalEditedPrompt: String? = nil) -> PromptInsertion {
        let text = finalEditedPrompt ?? preview.correctedPrompt
        return PromptInsertion(text: text)
    }
}

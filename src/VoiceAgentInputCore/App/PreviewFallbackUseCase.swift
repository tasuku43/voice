import Foundation

public struct PreviewFallback: Codable, Equatable, Sendable {
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

public struct PreviewFallbackUseCase: Sendable {
    public var normalizationUseCase: PromptNormalizationUseCase

    public init(normalizationUseCase: PromptNormalizationUseCase) {
        self.normalizationUseCase = normalizationUseCase
    }

    public init(entries: [DictionaryEntry]) {
        self.normalizationUseCase = PromptNormalizationUseCase(entries: entries)
    }

    public func fallback(rawTranscript: String) -> PreviewFallback {
        let result = normalizationUseCase.normalize(rawText: rawTranscript)
        return PreviewFallback(
            rawTranscript: result.rawText,
            correctedPrompt: result.correctedText,
            corrections: result.corrections
        )
    }

    public func makeInsertion(fallback: PreviewFallback, finalEditedPrompt: String? = nil) -> PromptInsertion {
        let text = finalEditedPrompt ?? fallback.correctedPrompt
        return PromptInsertion(text: text)
    }
}

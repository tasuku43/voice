import Foundation

public struct NormalizationContext: Equatable, Sendable {
    public var entries: [DictionaryEntry]

    public init(entries: [DictionaryEntry]) {
        self.entries = entries
    }
}

public struct NormalizedPrompt: Equatable, Sendable {
    public var rawText: String
    public var normalizedText: String
    public var corrections: [AppliedCorrection]

    public init(rawText: String, normalizedText: String, corrections: [AppliedCorrection]) {
        self.rawText = rawText
        self.normalizedText = normalizedText
        self.corrections = corrections
    }

    public init(result: NormalizationResult) {
        self.init(
            rawText: result.rawText,
            normalizedText: result.correctedText,
            corrections: result.corrections
        )
    }
}

public protocol PromptNormalizer {
    func normalize(_ transcript: Transcript, context: NormalizationContext) throws -> NormalizedPrompt
}

public extension PromptNormalizer {
    func normalizeText(_ text: String, context: NormalizationContext) throws -> String {
        try normalize(Transcript(text: text), context: context).normalizedText
    }
}

public struct DictionaryPromptNormalizer: PromptNormalizer, Sendable {
    public init() {}

    public func normalize(_ transcript: Transcript, context: NormalizationContext) throws -> NormalizedPrompt {
        let result = PromptNormalizationUseCase(entries: context.entries).normalize(rawText: transcript.text)
        return NormalizedPrompt(result: result)
    }
}

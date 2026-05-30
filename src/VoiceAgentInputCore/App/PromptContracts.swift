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

public struct RefinementInstruction: Equatable, Sendable {
    public var style: String

    public init(style: String = "preserve normalized prompt") {
        self.style = style
    }
}

public struct PromptRefinementChange: Equatable, Sendable {
    public var before: String
    public var after: String
    public var reason: String

    public init(before: String, after: String, reason: String) {
        self.before = before
        self.after = after
        self.reason = reason
    }
}

public struct RefinedPrompt: Equatable, Sendable {
    public var normalizedText: String
    public var refinedText: String
    public var changes: [PromptRefinementChange]
    public var warnings: [String]

    public init(
        normalizedText: String,
        refinedText: String,
        changes: [PromptRefinementChange] = [],
        warnings: [String] = []
    ) {
        self.normalizedText = normalizedText
        self.refinedText = refinedText
        self.changes = changes
        self.warnings = warnings
    }
}

public protocol PromptNormalizer {
    func normalize(_ transcript: Transcript, context: NormalizationContext) throws -> NormalizedPrompt
}

public protocol PromptRefiner {
    func refine(_ prompt: NormalizedPrompt, instruction: RefinementInstruction) async throws -> RefinedPrompt
}

public extension PromptNormalizer {
    func normalizeText(_ text: String, context: NormalizationContext) throws -> String {
        try normalize(Transcript(text: text), context: context).normalizedText
    }
}

public extension PromptRefiner {
    func refineText(_ text: String, instruction: RefinementInstruction = RefinementInstruction()) async throws -> String {
        let prompt = NormalizedPrompt(
            rawText: text,
            normalizedText: text,
            corrections: []
        )
        return try await refine(prompt, instruction: instruction).refinedText
    }
}

public struct DictionaryPromptNormalizer: PromptNormalizer, Sendable {
    public init() {}

    public func normalize(_ transcript: Transcript, context: NormalizationContext) throws -> NormalizedPrompt {
        let result = PromptNormalizationUseCase(entries: context.entries).normalize(rawText: transcript.text)
        return NormalizedPrompt(result: result)
    }
}

public struct NoOpPromptRefiner: PromptRefiner, Sendable {
    public init() {}

    public func refine(_ prompt: NormalizedPrompt, instruction: RefinementInstruction) async throws -> RefinedPrompt {
        RefinedPrompt(
            normalizedText: prompt.normalizedText,
            refinedText: prompt.normalizedText
        )
    }
}

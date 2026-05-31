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

public struct JapanesePunctuationPromptRefiner: PromptRefiner, Sendable {
    public init() {}

    public func refine(_ prompt: NormalizedPrompt, instruction: RefinementInstruction) async throws -> RefinedPrompt {
        let refined = Self.refineText(prompt.normalizedText)
        let changes = refined == prompt.normalizedText ? [] : [
            PromptRefinementChange(
                before: prompt.normalizedText,
                after: refined,
                reason: "Inserted lightweight Japanese punctuation around discourse markers."
            )
        ]
        return RefinedPrompt(
            normalizedText: prompt.normalizedText,
            refinedText: refined,
            changes: changes
        )
    }

    public static func refineText(_ text: String) -> String {
        let markers = ["というのも", "というのは", "なので", "ただ", "あと", "それで"]
        var refined = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for marker in markers {
            refined = insertSentenceBreak(before: marker, in: refined)
            refined = insertPause(after: marker, in: refined)
        }
        return refined
    }

    private static func insertSentenceBreak(before marker: String, in text: String) -> String {
        var output = ""
        var remaining = text[...]
        while let range = remaining.range(of: marker) {
            output += String(remaining[..<range.lowerBound])
            if shouldInsertSentenceBreak(before: range.lowerBound, in: remaining) {
                output += "。"
            }
            output += marker
            remaining = remaining[range.upperBound...]
        }
        output += String(remaining)
        return output
    }

    private static func insertPause(after marker: String, in text: String) -> String {
        var output = ""
        var remaining = text[...]
        while let range = remaining.range(of: marker) {
            output += String(remaining[..<range.upperBound])
            if shouldInsertPause(after: range.upperBound, in: remaining) {
                output += "、"
            }
            remaining = remaining[range.upperBound...]
        }
        output += String(remaining)
        return output
    }

    private static func shouldInsertSentenceBreak(before index: String.Index, in text: Substring) -> Bool {
        guard index > text.startIndex else {
            return false
        }
        let previous = text[text.index(before: index)]
        return !Self.isPunctuation(previous) && !previous.isWhitespace
    }

    private static func shouldInsertPause(after index: String.Index, in text: Substring) -> Bool {
        guard index < text.endIndex else {
            return false
        }
        let next = text[index]
        return !Self.isPunctuation(next) && !next.isWhitespace
    }

    private static func isPunctuation(_ character: Character) -> Bool {
        Set<Character>(["。", "、", ".", ",", "!", "?", "！", "？", "\n"]).contains(character)
    }
}

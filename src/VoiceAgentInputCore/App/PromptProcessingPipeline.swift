import Foundation

public struct PromptProcessingPipelineResult: Equatable, Sendable {
    public var transcript: Transcript
    public var normalizedPrompt: NormalizedPrompt
    public var insertion: PromptInsertion

    public init(
        transcript: Transcript,
        normalizedPrompt: NormalizedPrompt,
        insertion: PromptInsertion
    ) {
        self.transcript = transcript
        self.normalizedPrompt = normalizedPrompt
        self.insertion = insertion
    }
}

public struct PromptProcessingPipeline {
    public var normalizer: any PromptNormalizer
    public var normalizationContext: NormalizationContext

    public init(
        normalizer: any PromptNormalizer = DictionaryPromptNormalizer(),
        normalizationContext: NormalizationContext
    ) {
        self.normalizer = normalizer
        self.normalizationContext = normalizationContext
    }

    public func process(transcript: Transcript) async throws -> PromptProcessingPipelineResult {
        let normalized = try normalizer.normalize(transcript, context: normalizationContext)
        let insertion = PromptInsertion(text: normalized.normalizedText)
        return PromptProcessingPipelineResult(
            transcript: transcript,
            normalizedPrompt: normalized,
            insertion: insertion
        )
    }
}

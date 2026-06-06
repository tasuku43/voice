import Foundation

public struct PromptProcessingPipelineResult: Equatable, Sendable {
    public var transcript: Transcript
    public var normalizedPrompt: NormalizedPrompt
    public var refinement: PromptTextRefinementResult?
    public var insertion: PromptInsertion

    public init(
        transcript: Transcript,
        normalizedPrompt: NormalizedPrompt,
        refinement: PromptTextRefinementResult? = nil,
        insertion: PromptInsertion
    ) {
        self.transcript = transcript
        self.normalizedPrompt = normalizedPrompt
        self.refinement = refinement
        self.insertion = insertion
    }
}

public struct PromptProcessingPipeline {
    public var normalizer: any PromptNormalizer
    public var normalizationContext: NormalizationContext
    public var textRefiner: (any PromptTextRefiner)?

    public init(
        normalizer: any PromptNormalizer = DictionaryPromptNormalizer(),
        normalizationContext: NormalizationContext,
        textRefiner: (any PromptTextRefiner)? = nil
    ) {
        self.normalizer = normalizer
        self.normalizationContext = normalizationContext
        self.textRefiner = textRefiner
    }

    public func process(transcript: Transcript) async throws -> PromptProcessingPipelineResult {
        let normalized = try normalizer.normalize(transcript, context: normalizationContext)
        let refinement = try await textRefiner?.refine(
            PromptTextRefinementRequest(
                transcript: transcript,
                normalizedText: normalized.normalizedText
            )
        )
        let insertion = PromptInsertion(text: refinement?.refinedText ?? normalized.normalizedText)
        return PromptProcessingPipelineResult(
            transcript: transcript,
            normalizedPrompt: normalized,
            refinement: refinement,
            insertion: insertion
        )
    }
}

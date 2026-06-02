import Foundation

public struct PromptProcessingPipelineResult: Equatable, Sendable {
    public var transcript: Transcript
    public var normalizedPrompt: NormalizedPrompt
    public var refinedPrompt: RefinedPrompt
    public var insertion: PromptInsertion

    public init(
        transcript: Transcript,
        normalizedPrompt: NormalizedPrompt,
        refinedPrompt: RefinedPrompt,
        insertion: PromptInsertion
    ) {
        self.transcript = transcript
        self.normalizedPrompt = normalizedPrompt
        self.refinedPrompt = refinedPrompt
        self.insertion = insertion
    }
}

public struct PromptProcessingPipeline {
    public var normalizer: any PromptNormalizer
    public var refiner: any PromptRefiner
    public var normalizationContext: NormalizationContext

    public init(
        normalizer: any PromptNormalizer = DictionaryPromptNormalizer(),
        refiner: any PromptRefiner = NoOpPromptRefiner(),
        normalizationContext: NormalizationContext
    ) {
        self.normalizer = normalizer
        self.refiner = refiner
        self.normalizationContext = normalizationContext
    }

    public func process(transcript: Transcript) async throws -> PromptProcessingPipelineResult {
        let normalized = try normalizer.normalize(transcript, context: normalizationContext)
        let refined = try await refiner.refine(normalized)
        let insertion = PromptInsertion(text: refined.refinedText)
        return PromptProcessingPipelineResult(
            transcript: transcript,
            normalizedPrompt: normalized,
            refinedPrompt: refined,
            insertion: insertion
        )
    }
}

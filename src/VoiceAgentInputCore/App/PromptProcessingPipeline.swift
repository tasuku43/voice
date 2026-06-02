import Foundation

public struct PromptProcessingPipelineResult: Equatable, Sendable {
    public var transcript: Transcript
    public var normalizedPrompt: NormalizedPrompt
    public var refinedPrompt: RefinedPrompt
    public var insertion: PromptInsertion
    public var preview: PromptPreview

    public init(
        transcript: Transcript,
        normalizedPrompt: NormalizedPrompt,
        refinedPrompt: RefinedPrompt,
        insertion: PromptInsertion,
        preview: PromptPreview
    ) {
        self.transcript = transcript
        self.normalizedPrompt = normalizedPrompt
        self.refinedPrompt = refinedPrompt
        self.insertion = insertion
        self.preview = preview
    }
}

public struct PromptProcessingPipeline {
    public var normalizer: any PromptNormalizer
    public var refiner: any PromptRefiner
    public var normalizationContext: NormalizationContext
    public var refinementInstruction: RefinementInstruction

    public init(
        normalizer: any PromptNormalizer = DictionaryPromptNormalizer(),
        refiner: any PromptRefiner = NoOpPromptRefiner(),
        normalizationContext: NormalizationContext,
        refinementInstruction: RefinementInstruction = RefinementInstruction()
    ) {
        self.normalizer = normalizer
        self.refiner = refiner
        self.normalizationContext = normalizationContext
        self.refinementInstruction = refinementInstruction
    }

    public func process(transcript: Transcript) async throws -> PromptProcessingPipelineResult {
        let normalized = try normalizer.normalize(transcript, context: normalizationContext)
        let refined = try await refiner.refine(normalized, instruction: refinementInstruction)
        let preview = PromptPreview(
            rawTranscript: transcript.text,
            correctedPrompt: refined.refinedText,
            corrections: normalized.corrections
        )
        let insertion = PromptInsertion(text: refined.refinedText)
        return PromptProcessingPipelineResult(
            transcript: transcript,
            normalizedPrompt: normalized,
            refinedPrompt: refined,
            insertion: insertion,
            preview: preview
        )
    }
}

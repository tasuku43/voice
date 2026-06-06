import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26.0, *)
public struct FoundationModelPromptTextRefiner: PromptTextRefiner {
    public static let engineIdentifier = "FoundationModels.SystemLanguageModel"

    public var maximumResponseTokens: Int

    public init(maximumResponseTokens: Int = 1_000) {
        self.maximumResponseTokens = maximumResponseTokens
    }

    public func refine(_ request: PromptTextRefinementRequest) async throws -> PromptTextRefinementResult {
        let model = SystemLanguageModel(
            useCase: .general,
            guardrails: .permissiveContentTransformations
        )
        guard model.isAvailable else {
            throw FoundationModelPromptTextRefinerError.modelUnavailable(
                availability: String(describing: model.availability)
            )
        }

        let session = LanguageModelSession(
            model: model,
            instructions: Self.instructions
        )
        let response = try await session.respond(
            to: Self.prompt(for: request),
            options: GenerationOptions(
                sampling: .greedy,
                temperature: 0,
                maximumResponseTokens: maximumResponseTokens
            )
        )
        let refined = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !refined.isEmpty else {
            throw FoundationModelPromptTextRefinerError.emptyResult
        }
        return PromptTextRefinementResult(
            inputText: request.normalizedText,
            refinedText: refined,
            engine: Self.engineIdentifier
        )
    }

    private static var instructions: String {
        """
        You are a local Japanese dictation post-processor for developer prompts.
        Return only the corrected transcript text.
        Preserve the speaker's meaning and technical terms.
        Improve punctuation and paragraph breaks when clauses clearly continue across pauses.
        Use a blank line between paragraphs when the topic shifts, for example before a new question, before "まず", or before "そうすると".
        Do not split a sentence just because the speaker paused.
        Remove obvious fillers and false starts only when they do not change meaning.
        Prefer preserving words over replacing them with a guess.
        Do not summarize, add facts, answer the prompt, or wrap the result in markdown.
        """
    }

    private static func prompt(for request: PromptTextRefinementRequest) -> String {
        """
        Raw STT transcript:
        \(request.transcript.text)

        Deterministically normalized text:
        \(request.normalizedText)

        Produce the final corrected transcript.
        """
    }
}

public enum FoundationModelPromptTextRefinerError: Error, Equatable, Sendable {
    case modelUnavailable(availability: String)
    case emptyResult
}
#endif

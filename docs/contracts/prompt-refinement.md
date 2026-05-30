# Prompt Refinement Contract

## Inputs
- `NormalizedPrompt`
- `RefinementInstruction`
- Optional short context in future implementations.

## Outputs
- `RefinedPrompt`
- `PromptRefinementChange`
- Warnings when needed.
- `refineText(_:instruction:)` is the convenience `String -> String` form.
- `RefinementPromptTextTransform` adapts refinement to `PromptTextTransform`.

## Allowed
- Remove filler words, format, or lightly summarize after normalization.
- Be swapped for a local LLM implementation later.

## Forbidden
- Speech recognition.
- Dictionary correction.
- Persistence, paste, automatic submit, or command execution.
- Cloud calls unless a future explicit local-first decision changes the product boundary.

## Read First
- `src/VoiceAgentInputCore/App/PromptContracts.swift`
- `src/VoiceAgentInputCore/App/VoiceInputPipeline.swift`

## May Touch
- `PromptRefiner` implementations and tests.

## Avoid Touching
- Speech, repository vocabulary, and UI presentation code.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testNoOpPromptRefinerPreservesNormalizedPrompt`
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineKeepsTranscriptNormalizationRefinementAndPreviewStages`
- `make check`

## Done
- `NoOpPromptRefiner` remains the default.
- Refinement cannot paste, submit, or persist data.

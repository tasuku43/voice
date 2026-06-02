# Prompt Refinement Contract

## Inputs
- `NormalizedPrompt`

## Outputs
- `RefinedPrompt`
- `PromptRefinementChange`
- Warnings when needed.
- `refineText(_:)` is the convenience `String -> String` form.
- `RefinementPromptTextTransform` adapts refinement to `PromptTextTransform`.

## Allowed
- Apply deterministic local cleanup after normalization.
- Add lightweight punctuation or formatting rules that preserve the user's meaning.
- Run in the hotkey path only when the implementation is deterministic and local.

## Forbidden
- Speech recognition.
- Dictionary correction.
- Persistence, paste, automatic submit, or command execution.
- Network IO.
- Cloud LLM calls.
- LLM-backed rewriting in the default hotkey path.

## Read First
- `src/VoiceAgentInputCore/App/PromptContracts.swift`
- `src/VoiceAgentInputCore/App/VoiceInputPipeline.swift`

## May Touch
- `PromptRefiner` implementations and tests.

## Avoid Touching
- Speech, repository vocabulary, and UI presentation code.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testNoOpPromptRefinerPreservesNormalizedPrompt`
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineKeepsTranscriptNormalizationRefinementAndInsertionStages`
- `make check`

## Done
- `NoOpPromptRefiner` remains the default.
- Refinement cannot paste, submit, or persist data.
- Foundation Model conversion belongs to an explicit local-only fallback stage, not this default refiner contract.

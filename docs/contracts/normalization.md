# Text Normalization Contract

## Inputs
- `Transcript`
- `NormalizationContext`
- Global, user, repository, and session dictionary entries.

## Outputs
- `NormalizedPrompt`
- Applied corrections with reasons from dictionary metadata.
- `normalizeText(_:context:)` is the convenience `String -> String` form.

## Allowed
- Deterministic replacement using dictionary and repository vocabulary.
- Preserve correction metadata for diagnostics and model education.

## Forbidden
- Audio capture or speech recognition.
- Foundation Model rewriting or summarization inside this deterministic normalization contract.
- Preview UI, paste, or persistence.

Local Foundation Model conversion belongs to a separate explicit `PromptTextRefiner` stage after deterministic normalization. It must not change the dictionary normalizer into an LLM-backed rewrite path.

## Read First
- `src/VoiceAgentInputCore/App/PromptContracts.swift`
- `src/VoiceAgentInputCore/App/PromptNormalizationUseCase.swift`
- `src/VoiceAgentInputCore/Domain/NormalizationEngine.swift`

## May Touch
- Domain normalization types and normalization use-case tests.

## Avoid Touching
- AppKit UI files and output adapters.

## Tests
- `swift test --filter NormalizationEngineTests`
- `swift test --filter EvalHarnessTests`
- `make check`

## Done
- Dictionary-only corrections are deterministic and fixture-backed.
- No learning side effect is introduced.

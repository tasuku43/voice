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
- Foundation Model rewriting, summarization, preview UI, paste, or persistence.

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

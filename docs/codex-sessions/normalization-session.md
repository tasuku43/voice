# Normalization Session

Purpose: improve deterministic dictionary and repository-term correction.

Read:
- `docs/contracts/normalization.md`
- `src/VoiceAgentInputCore/App/PromptTextTransform.swift`
- `src/VoiceAgentInputCore/Domain/NormalizationEngine.swift`
- `evals/normalization-cases.json`

May touch:
- Normalization domain types, seed dictionaries, eval fixtures, normalization tests.

Avoid:
- Speech engines and output adapters.

Contract:
- Dictionary-only corrections, no LLM rewriting.
- The simple layer shape is `PromptTextTransform.transform(String) async throws -> String`.

Tests:
- `swift test --filter NormalizationEngineTests`
- `swift test --filter EvalHarnessTests`
- `make check`

Done:
- New terms are fixture-backed and correction metadata stays intact.

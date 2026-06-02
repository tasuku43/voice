# Normalization Session

Purpose: improve deterministic dictionary and repository-term correction.

Read:
- `docs/contracts/normalization.md`
- `src/VoiceAgentInputCore/Domain/NormalizationEngine.swift`
- `evals/normalization-cases.json`

May touch:
- Normalization domain types, seed dictionaries, eval fixtures, normalization tests.

Avoid:
- Speech engines and output adapters.

Contract:
- Dictionary-only corrections, no LLM rewriting.
- Use `PromptNormalizer.normalizeText(_:context:)` for simple `String -> String` checks.

Tests:
- `swift test --filter NormalizationEngineTests`
- `swift test --filter EvalHarnessTests`
- `make check`

Done:
- New terms are fixture-backed and correction metadata stays intact.

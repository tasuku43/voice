# Prompt Refinement Session

Purpose: implement or improve local prompt refinement behind `PromptRefiner`.

Read:
- `docs/contracts/prompt-refinement.md`
- `src/VoiceAgentInputCore/App/PromptContracts.swift`
- `src/VoiceAgentInputCore/App/PromptProcessingPipeline.swift`
- `src/VoiceAgentInputCore/App/PromptTextTransform.swift`
- `src/VoiceAgentInputCore/App/VoiceInputPipeline.swift`

May touch:
- `PromptRefiner` implementations and pipeline tests.

Avoid:
- Speech, dictionary persistence, output adapters, cloud networking.

Contract:
- Default remains local and no-op unless explicitly configured.
- The simple layer shape is `PromptTextTransform.transform(String) async throws -> String`.
- No automatic submit or command execution.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testNoOpPromptRefinerPreservesNormalizedPrompt`
- `swift test --filter UseCaseAndRepositoryTests/testPromptProcessingPipelineRunsAfterSTTWithoutAudioDependencies`
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineKeepsTranscriptNormalizationRefinementAndInsertionStages`
- `make check`

Done:
- Refinement output is visible as `RefinedPrompt` and can be disabled.

# Voice Input Pipeline Contract

## Inputs
- Optional `AudioRecorder`
- `SpeechToTextEngine`
- `PromptNormalizer`
- `PromptRefiner`
- `NormalizationContext`

## Outputs
- `VoiceInputPipelineResult`
- Stage data: `Transcript`, `NormalizedPrompt`, `RefinedPrompt`, `PromptPreview`

`VoiceInputPipeline` owns capture and STT orchestration. `PromptProcessingPipeline` owns the post-STT text path:

```text
Transcript.text
-> PromptNormalizer.normalizeText
-> PromptRefiner.refineText
-> PromptPreview.correctedPrompt
-> ConfirmedPrompt.promptToInsert
```

Dictionary and refinement layers also expose the common `PromptTextTransform` shape:

```text
PromptTextTransform.transform(String) async throws -> String
```

Use `PromptTextTransformPipeline` when a session only needs function composition and does not need correction metadata.

## Allowed
- Orchestrate audio, speech, normalization, refinement, and preview model creation.
- Preserve stage outputs for debugging and component tests.

## Forbidden
- AppKit UI rendering.
- Local dictionary approval persistence.
- Paste or automatic submit.

## Read First
- `src/VoiceAgentInputCore/App/VoiceInputPipeline.swift`
- `src/VoiceAgentInputCore/App/PromptProcessingPipeline.swift`
- `src/VoiceAgentInputCore/App/PromptTextTransform.swift`
- `src/VoiceAgentInputCore/App/VoiceInputFlowUseCase.swift`
- `src/VoiceAgentInputCore/App/DictionaryContextLoadingUseCase.swift`

## May Touch
- Pipeline orchestration and use-case tests.

## Avoid Touching
- Infra adapter internals unless a protocol is missing.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineKeepsTranscriptNormalizationRefinementAndPreviewStages`
- `swift test --filter UseCaseAndRepositoryTests/testPromptProcessingPipelineRunsAfterSTTWithoutAudioDependencies`
- `make check`

## Done
- Stage outputs remain visible.
- UI and output actions stay outside the pipeline.

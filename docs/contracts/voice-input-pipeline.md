# Voice Input Pipeline Contract

## Inputs
- Optional `AudioRecorder`
- `SpeechToTextEngine`
- `PromptNormalizer`
- `NormalizationContext`
- Local context model recognition hints.

## Outputs
- `VoiceInputPipelineResult`
- Stage data: `Transcript`, `NormalizedPrompt`, `PromptInsertion`

`VoiceInputPipeline` owns capture and STT orchestration. `PromptProcessingPipeline` owns the post-STT text path:

```text
RecordedAudio
-> SpeechToTextEngine.transcribe(recognitionHints:)
-> built-in vocabulary transform
-> personal context model transform
-> optional local Foundation Model fallback
-> corrected transcript for insertion
```

Dictionary normalization exposes `PromptNormalizer.normalizeText(_:context:)` for simple `String -> String` checks when correction metadata is not needed.

## Allowed
- Orchestrate audio, speech, normalization, and insertion text creation.
- Pass local recognition hints into STT adapters that support contextual strings.
- Keep local Foundation Model conversion as an optional fallback stage.
- Preserve stage outputs for debugging and component tests.

## Forbidden
- AppKit UI rendering.
- Local context model persistence.
- Paste or automatic submit.
- Network IO.
- Cloud STT or cloud LLM calls.

## Read First
- `src/VoiceAgentInputCore/App/VoiceInputPipeline.swift`
- `src/VoiceAgentInputCore/App/PromptProcessingPipeline.swift`
- `src/VoiceAgentInputCore/App/DictionaryContextLoadingUseCase.swift`

## May Touch
- Pipeline orchestration and use-case tests.

## Avoid Touching
- Infra adapter internals unless a protocol is missing.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineKeepsTranscriptNormalizationAndInsertionStages`
- `swift test --filter UseCaseAndRepositoryTests/testPromptProcessingPipelineRunsAfterSTTWithoutAudioDependencies`
- `make check`

## Done
- Stage outputs remain visible.
- UI and output actions stay outside the pipeline.
- The normal hotkey path remains local and mostly deterministic.

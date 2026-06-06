# Voice Input Pipeline Contract

## Inputs
- Optional `AudioRecorder`
- `SpeechToTextEngine`
- `PromptNormalizer`
- `NormalizationContext`
- Optional `PromptTextRefiner`
- Local context model recognition hints.

## Outputs
- `VoiceInputPipelineResult`
- Stage data: `Transcript`, `NormalizedPrompt`, optional `PromptTextRefinementResult`, `PromptInsertion`

`VoiceInputPipeline` owns capture and STT orchestration. `PromptProcessingPipeline` owns the shared post-STT text path:

```text
RecordedAudio
-> SpeechToTextEngine.transcribe(recognitionHints:)
-> built-in vocabulary transform
-> personal context model transform
-> optional local Foundation Model refinement
-> corrected transcript for insertion
```

Foundation Model refinement can be enabled in the shared post-STT pipeline used by both `TranscribeCLI` and hotkey recording. It remains local-only, optional, and after deterministic transforms; the default hotkey path can run without it.

Dictionary normalization exposes `PromptNormalizer.normalizeText(_:context:)` for simple `String -> String` checks when correction metadata is not needed.

## Allowed
- Orchestrate audio, speech, normalization, and insertion text creation.
- Pass local recognition hints into STT adapters that support contextual strings.
- Keep local Foundation Model conversion as an explicitly enabled optional refinement stage after deterministic transforms, not as a replacement for STT or dictionary normalization.
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
- `src/VoiceAgentInputCore/App/PromptTextRefiner.swift`
- `src/VoiceAgentInputCore/App/DictionaryContextLoadingUseCase.swift`

## May Touch
- Pipeline orchestration and use-case tests.

## Avoid Touching
- Infra adapter internals unless a protocol is missing.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineKeepsTranscriptNormalizationAndInsertionStages`
- `swift test --filter UseCaseAndRepositoryTests/testPromptProcessingPipelineRunsAfterSTTWithoutAudioDependencies`
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineCanApplySharedTextRefinerOnHotkeyPath`
- `make check`

## Done
- Stage outputs remain visible.
- UI and output actions stay outside the pipeline.
- The normal hotkey path remains local and mostly deterministic.

# Speech To Text Session

Purpose: improve speech recognition accuracy while keeping SpeechEngine raw and local-first.

Read:
- `docs/contracts/speech-to-text.md`
- `src/VoiceAgentInputCore/App/SpeechToTextEngine.swift`
- `src/VoiceAgentInputCore/App/TranscriptionOptions.swift`
- `src/VoiceAgentInputCore/App/TranscriptionResult.swift`
- `src/VoiceAgentInputCore/App/TranscriptionQualityEvaluation.swift`
- `src/VoiceAgentInputCore/App/PromptTextRefiner.swift`
- `src/VoiceAgentInputCore/App/SpeechEngineError.swift`
- `src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift`
- `src/TranscribeCLI/main.swift`

May touch:
- Speech engine adapters, mocks, CLI evaluation helpers, and speech tests.

Avoid:
- `VoiceAgentInputApp/VoiceAgentInputApp.swift`
- Domain normalization and output adapters.

Contract:
- Return `TranscriptionResult` for file-based engine checks and `Transcript` for the hotkey bridge.
- Do not correct developer terms inside `SpeechEngine` or persist transcripts.
- CLI `--normalize` / `--corrections` may run deterministic post-STT normalization explicitly for repeatable local quality evaluation.
- CLI `--batch`, `--smooth-pauses`, and `--foundation-model` may run shared post-STT refinement and distance metrics outside `SpeechEngine`.
- Keep SpeechAnalyzer-specific details inside infra; app use cases see only shared result and option types.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineTranscribesThroughReplaceableEngineBeforeProcessing`
- `swift test --filter UseCaseAndRepositoryTests/testTranscriptionQualityEvaluationReportsCharacterErrorRate`
- `swift test --filter DemoCLITests/testTranscribeCLIHelpUsesRealExecutablePath`
- `make check`

Done:
- Speech behavior is tested and local-first privacy still passes.

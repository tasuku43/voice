# Speech To Text Session

Purpose: improve speech recognition accuracy without changing normalization, learning, or output.

Read:
- `docs/contracts/speech-to-text.md`
- `src/VoiceAgentInputCore/App/SpeechToTextEngine.swift`
- `src/VoiceAgentInputCore/App/TranscriptionOptions.swift`
- `src/VoiceAgentInputCore/App/TranscriptionResult.swift`
- `src/VoiceAgentInputCore/App/SpeechEngineError.swift`
- `src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift`
- `src/TranscribeCLI/main.swift`

May touch:
- Speech engine adapters, mocks, and speech tests.

Avoid:
- `VoiceAgentInputApp/VoiceAgentInputApp.swift`
- Domain normalization and output adapters.

Contract:
- Return `TranscriptionResult` for file-based engine checks and `Transcript` for the hotkey bridge.
- Do not correct developer terms or persist transcripts.
- Keep SpeechAnalyzer-specific details inside infra; app use cases see only shared result and option types.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineTranscribesThroughReplaceableEngineBeforeProcessing`
- `swift test --filter DemoCLITests/testTranscribeCLIHelpUsesRealExecutablePath`
- `make check`

Done:
- Speech behavior is tested and local-first privacy still passes.

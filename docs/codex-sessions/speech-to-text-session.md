# Speech To Text Session

Purpose: improve speech recognition accuracy without changing normalization, learning, or output.

Read:
- `docs/contracts/speech-to-text.md`
- `src/VoiceAgentInputCore/App/SpeechToTextEngine.swift`
- `src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift`

May touch:
- Speech engine adapters, mocks, and speech tests.

Avoid:
- `VoiceAgentInputApp/VoiceAgentInputApp.swift`
- Domain normalization and output adapters.

Contract:
- Return `Transcript` only.
- Do not correct developer terms or persist transcripts.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineTranscribesThroughReplaceableEngineBeforeProcessing`
- `make check`

Done:
- Speech behavior is tested and local-first privacy still passes.

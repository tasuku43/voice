# Speech To Text Contract

## Inputs
- `RecordedAudio`
- Speech locale from `AppSettings`

## Outputs
- `Transcript`
- Optional confidence on `Transcript`

## Allowed
- Convert one audio input into raw transcript text.
- Report recognition availability or transcription failure.

## Forbidden
- Dictionary correction.
- Prompt refinement or summarization.
- Preview, paste, learning, or persistence.

## Read First
- `src/VoiceAgentInputCore/App/SpeechToTextEngine.swift`
- `src/VoiceAgentInputCore/App/Transcript.swift`
- `src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift`

## May Touch
- Speech engine protocols, mocks, and infra adapters.

## Avoid Touching
- `VoiceAgentInputApp/VoiceAgentInputApp.swift`
- Normalization, learning, and output use cases.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputFlowTranscribesThroughReplaceableEngineBeforePreview`
- `make check`

## Done
- Raw transcript behavior is covered by tests.
- No dictionary, preview, or paste behavior leaks into speech code.

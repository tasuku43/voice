# Speech To Text Contract

## Inputs
- `RecordedAudio`
- Adapter-owned fixed local Speech locale, currently `ja-JP`.
- Optional `SpeechRecognitionHints` derived from loaded `DictionaryEntry.recognitionHints` values.

## Outputs
- `Transcript`
- Optional confidence on `Transcript`

## Allowed
- Convert one audio input into raw transcript text.
- Report recognition availability or transcription failure.
- Pass domain vocabulary hints to Apple Speech through `SFSpeechRecognitionRequest.contextualStrings`.
- Prefer ASR-friendly `recognitionHints` over post-STT `spokenForms` when building contextual strings.
- Consume recorder-provided temporary audio file URLs directly, deleting temporary audio after recognition completes.

## Forbidden
- Dictionary correction.
- Post-STT text conversion or summarization.
- Preview, paste, learning, or persistence.

## Read First
- `src/VoiceAgentInputCore/App/SpeechToTextEngine.swift`
- `src/VoiceAgentInputCore/App/SpeechRecognitionHints.swift`
- `src/VoiceAgentInputCore/App/Transcript.swift`
- `src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift`

## May Touch
- Speech engine protocols, mocks, and infra adapters.

## Avoid Touching
- `VoiceAgentInputApp/VoiceAgentInputApp.swift`
- Normalization, learning, and output use cases.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineTranscribesThroughReplaceableEngineBeforeProcessing`
- `swift test --filter UseCaseAndRepositoryTests/testAppleSpeechEngineUsesExistingTemporaryRecordingFileAndDeletesItAfterOperation`
- `make check`

## Done
- Raw transcript behavior is covered by tests.
- Learned dictionary entries keep ASR-friendly `recognitionHints` that can be converted into speech recognition contextual strings before ASR.
- No dictionary, preview, or paste behavior leaks into speech code.

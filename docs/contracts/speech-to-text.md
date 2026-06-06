# Speech To Text Contract

## Inputs
- `RecordedAudio`
- Audio file URL for direct engine checks.
- `TranscriptionOptions`, including locale, tagged contextual strings, recognition mode, output detail level, and transcriber profile.
- Optional `SpeechRecognitionHints` derived from loaded `DictionaryEntry.recognitionHints` values and converted into `ContextualStringsConfig`.

## Outputs
- `TranscriptionResult`
- `Transcript`
- Optional confidence, segments, alternatives, and metadata when the underlying SpeechAnalyzer result exposes them.

## Allowed
- Convert one audio input into raw transcript text.
- Report recognition availability or transcription failure.
- Pass domain vocabulary hints to Apple Speech through `AnalysisContext.contextualStrings`.
- Prefer ASR-friendly `recognitionHints` over post-STT `spokenForms` when building contextual strings.
- Consume recorder-provided temporary audio file URLs directly, deleting temporary audio after recognition completes.
- Use `SpeechAnalyzer` with `DictationTranscriber` or `SpeechTranscriber` for local file transcription.
- Check that required on-device speech assets are already installed.
- Reserve already-installed local speech assets before transcription when `AssetInventory.status` is supported-but-not-installed.

## Forbidden
- Dictionary correction.
- Post-STT text conversion or summarization.
- Preview, paste, learning, or persistence.
- Automatic post-STT normalization inside `SpeechEngine`.
- `SFSpeechRecognizer` or `SFSpeechURLRecognitionRequest` as a transcription implementation.
- Automatic speech asset downloads in the normal hotkey path.
- Local Foundation Model rewriting inside `SpeechEngine`; use `PromptTextRefiner` after deterministic normalization instead.

## Read First
- `src/VoiceAgentInputCore/App/SpeechToTextEngine.swift`
- `src/VoiceAgentInputCore/App/SpeechRecognitionHints.swift`
- `src/VoiceAgentInputCore/App/TranscriptionOptions.swift`
- `src/VoiceAgentInputCore/App/TranscriptionResult.swift`
- `src/VoiceAgentInputCore/App/TranscriptionQualityEvaluation.swift`
- `src/VoiceAgentInputCore/App/PromptTextRefiner.swift`
- `src/VoiceAgentInputCore/App/SpeechEngineError.swift`
- `src/VoiceAgentInputCore/App/Transcript.swift`
- `src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift`
- `src/TranscribeCLI/main.swift`

## May Touch
- Speech engine protocols, mocks, and infra adapters.

## Avoid Touching
- `VoiceAgentInputApp/VoiceAgentInputApp.swift`
- Normalization, learning, and output use cases.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineTranscribesThroughReplaceableEngineBeforeProcessing`
- `swift test --filter UseCaseAndRepositoryTests/testAppleSpeechEngineUsesExistingTemporaryRecordingFileAndDeletesItAfterOperation`
- `swift test --filter UseCaseAndRepositoryTests/testTranscriptionQualityEvaluationReportsCharacterErrorRate`
- `swift test --filter DemoCLITests/testTranscribeCLIHelpUsesRealExecutablePath`
- `make check`

## Done
- Raw transcript behavior is covered by tests.
- Learned dictionary entries keep ASR-friendly `recognitionHints` that can be converted into speech recognition contextual strings before ASR.
- No dictionary, preview, or paste behavior leaks into speech code.
- `swift run TranscribeCLI /path/to/audio.caf --locale ja-JP --context contextual-strings.json --expected expected.txt --json` exercises the same SpeechEngine path without hotkey, Accessibility, or paste state.

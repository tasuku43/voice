# Provider and adapter contracts

## SpeechToTextEngine

Future protocol:

```swift
protocol SpeechToTextEngine {
    func transcribe(audio: RecordedAudio) async throws -> Transcript
}
```

Implementations:

- `MockSpeechEngine` for tests and UI development.
- `AppleSpeechEngine` for SpeechAnalyzer / SpeechTranscriber.
- `WhisperSpeechEngine` optional fallback later.

Current app orchestration:

- `VoiceInputFlowUseCase` accepts a `SpeechToTextEngine` and produces a `PromptPreview`.
- Mock transcription is supported for tests and preview UI development before microphone capture exists.

## DictionaryRepository

Current adapter:

- `JSONDictionaryRepository`

Current use cases:

- `DictionaryLearningUseCase` persists only approved candidates as local dictionary entries.
- Dangerous command candidates may be stored after explicit approval, but they are saved with `autoApply = false`.

Future adapter:

- SQLite-backed repository if candidate history becomes large.

## TextInsertionController

Current protocol:

```swift
protocol TextInsertionController {
    func insert(_ request: TextInsertionRequest) throws
}
```

Current test adapter:

- `MockTextInsertionController`

Current macOS adapter:

- `PasteboardTextInsertionController`

Future adapters:

- `AccessibilityInserter`

Rules:

- Insert only after explicit confirmation.
- Never press Enter or submit the target app automatically.
- Consume `ConfirmedPrompt.promptToInsert`; ignore candidate data for insertion.
- Reject insertion if `ConfirmedPrompt.shouldSubmitAutomatically` is true.
- Pasteboard insertion writes text to the pasteboard only. A separate UI action must decide whether to paste.

## ContextProvider

Future providers:

- focused app provider,
- terminal current directory provider,
- git context provider,
- repository vocabulary provider.

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

## DictionaryRepository

Current adapter:

- `JSONDictionaryRepository`

Future adapter:

- SQLite-backed repository if candidate history becomes large.

## TextInsertionController

Future adapters:

- `PasteboardInserter`
- `AccessibilityInserter`

Rules:

- Insert only after explicit confirmation.
- Never press Enter or submit the target app automatically.

## ContextProvider

Future providers:

- focused app provider,
- terminal current directory provider,
- git context provider,
- repository vocabulary provider.

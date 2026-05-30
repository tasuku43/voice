# Provider and adapter contracts

## SpeechToTextEngine

Current protocol:

```swift
protocol SpeechToTextEngine {
    func transcribe(audio: RecordedAudio) async throws -> Transcript
}
```

## AudioRecorder

Current protocol:

```swift
protocol AudioRecorder {
    func recordOnce() async throws -> RecordedAudio
}
```

Implementations:

- `MockAudioRecorder` for tests and UI development.
- `MockSpeechEngine` for tests and UI development.
- `AppleSpeechEngine` for SpeechAnalyzer / SpeechTranscriber.
- `WhisperSpeechEngine` optional fallback later.

Current app orchestration:

- `VoiceInputFlowUseCase` accepts an optional `AudioRecorder`, a `SpeechToTextEngine`, and produces a `PromptPreview`.
- Mock transcription is supported for tests and preview UI development before microphone capture exists.

## MicrophonePermissionProvider

Current protocol:

```swift
protocol MicrophonePermissionProvider {
    func currentStatus() -> MicrophonePermissionStatus
    func requestAccess() async -> MicrophonePermissionStatus
}
```

Current use cases:

- `MicrophonePermissionUseCase` requests access only when the status is `notDetermined`.
- `VoiceInputFlowUseCase` can check microphone permission before recording when a provider is injected.

Current test adapter:

- `MockMicrophonePermissionProvider`

Future macOS adapter:

- AVFoundation-backed provider using microphone authorization APIs.

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

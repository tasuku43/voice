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
- `AVFoundationAudioRecorder` records a short local microphone clip to a temporary file, reads it into `RecordedAudio`, and deletes the temporary file immediately.
- `MockSpeechEngine` for tests and UI development.
- `AppleSpeechEngine` for on-device local file transcription through `SFSpeechRecognizer`.
- `WhisperSpeechEngine` optional fallback later.

Current app orchestration:

- `VoiceInputFlowUseCase` accepts an optional `AudioRecorder`, a `SpeechToTextEngine`, and produces a `PromptPreview`.
- The macOS shell records audio, checks speech recognition permission, and transcribes through `AppleSpeechEngine`.
- `AppleSpeechEngine` defaults to `requiresOnDeviceRecognition = true` to avoid uploading audio for recognition.

## SpeechRecognitionPermissionProvider

Current protocol:

```swift
protocol SpeechRecognitionPermissionProvider {
    func currentStatus() -> SpeechRecognitionPermissionStatus
    func requestAccess() async -> SpeechRecognitionPermissionStatus
}
```

Current use cases:

- `SpeechRecognitionPermissionUseCase` requests access only when the status is `notDetermined`.

Current adapters:

- `MockSpeechRecognitionPermissionProvider`
- `SFSpeechRecognitionPermissionProvider`

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

Current macOS adapter:

- `AVFoundationMicrophonePermissionProvider`

## DictionaryRepository

Current adapter:

- `JSONDictionaryRepository`
- `LocalLearningDictionaryStore` creates the Application Support-backed JSON repository used by the macOS shell.

Current use cases:

- `DictionaryEntryLoadingUseCase` combines seed dictionary entries with approved local entries for preview and confirmation flows.
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

## KeyboardShortcutMonitor

Current protocol:

```swift
protocol KeyboardShortcutMonitor {
    func start(shortcut: KeyboardShortcut, onTrigger: @escaping () -> Void)
    func stop()
}
```

Current default shortcut:

- Command-Shift-Space

Current test adapter:

- `MockKeyboardShortcutMonitor`

Current macOS adapter:

- `AppKitKeyboardShortcutMonitor` in the app shell.

App shell rules:

- Command-Shift-Space starts the same record/transcribe/preview path as the menu item.
- Repeated hotkey/menu triggers are ignored while a recording/transcription flow is active.

## ContextProvider

Future providers:

- focused app provider,
- terminal current directory provider,
- git context provider,
- repository vocabulary provider.

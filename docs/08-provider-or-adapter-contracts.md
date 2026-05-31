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
- `AppleSpeechEngine` for on-device local file transcription through `SFSpeechRecognizer`; its temporary audio file is created through `TemporaryRecordedAudioFileStore` and deleted after success or failure.
- `WhisperSpeechEngine` optional fallback later.

Current app orchestration:

- `VoiceInputPipeline` accepts an optional `AudioRecorder`, a `SpeechToTextEngine`, a `PromptNormalizer`, a `PromptRefiner`, and `NormalizationContext`.
- `VoiceInputPipeline.run()` preserves `Transcript`, `NormalizedPrompt`, `RefinedPrompt`, and `PromptPreview` stage outputs.
- `VoiceInputFlowUseCase` remains as a compatibility wrapper for preview-oriented tests and CLI-style call sites.
- The macOS shell records audio, checks speech recognition permission, and transcribes through `AppleSpeechEngine` by calling `VoiceInputPipeline.run()`.
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
- `VoiceInputPipeline` can check microphone permission before recording when a provider is injected.
- `VoiceInputFlowUseCase` delegates to `VoiceInputPipeline` for compatibility.

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
- `CandidateApprovalUseCase` marks selected candidates as approved and unselected candidates as rejected.
- `DictionaryLearningUseCase` persists only candidates marked `approved` and not `rejected` as local dictionary entries.
- `LearningApprovalUseCase` combines candidate selection review and approved-entry persistence so UI only supplies selected indexes.
- `LocalLearningDataUseCase` exports, imports, and deletes approved local dictionary entries; the macOS shell exposes these as menu actions.
- `LocalLearningDataDocumentCodec` owns the JSON document shape for local dictionary import/export.
- `AppSettingsUseCase` owns repository path and recording setting updates so the UI does not duplicate clamping and trimming rules.
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
- `AccessibilityTextInsertionController`

Future adapters:

- `AccessibilityInserter`

Rules:

- Insert only after explicit confirmation.
- Never press Enter or submit the target app automatically.
- Consume `ConfirmedPrompt.promptToInsert`; ignore candidate data for insertion.
- Reject insertion if `ConfirmedPrompt.shouldSubmitAutomatically` is true.
- Pasteboard insertion writes text to the pasteboard only.
- Accessibility insertion writes text to the pasteboard and sends Command-V only. It never presses Enter.
- The app shell falls back to pasteboard-only insertion when Accessibility access is not granted.

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

Current providers:

- `GitRepositoryContextProvider` reads git root, current branch, and a bounded list of tracked file paths through `git` commands.
- `RepositoryVocabularyUseCase` turns repository name, branch name, and tracked file names into repository-scoped dictionary entries.
- The macOS shell currently reads repository context from the configured repository folder or app process working directory and mixes those entries into preview dictionaries.
- `JSONAppSettingsRepository` stores local app settings, including an optional repository folder override and optional local learning-reviewer command path.
- `LocalAgentHistoryTextProvider` reads bounded local Codex and Claude history text for explicit learning mode.
- `LocalCommandLearningCandidateReviewer` invokes a user-configured local command through stdin/stdout JSON after preview confirmation. It is an infra adapter for candidate review only, not speech recognition or prompt transformation. The interactive app passes a short timeout and falls back to unreviewed candidates if optional review fails.

Future providers:

- focused app provider,
- terminal current directory provider,
- repository vocabulary provider.

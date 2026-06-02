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
- `AVFoundationAudioRecorder` records a short local microphone clip to a temporary file and returns that URL in `RecordedAudio` so STT adapters can avoid a second audio write.
- `MockSpeechEngine` for tests and UI development.
- `AppleSpeechEngine` for on-device local file transcription through `SFSpeechRecognizer`; it uses recorder-provided temporary file URLs directly when available, otherwise creates a temporary file through `TemporaryRecordedAudioFileStore`. Temporary audio is deleted after success or failure.
- `AppleSpeechEngine` accepts `SpeechRecognitionHints` and maps them to `SFSpeechRecognitionRequest.contextualStrings` so loaded dictionary entries can help ASR before post-STT normalization.
- `WhisperSpeechEngine` optional fallback later.

Current app orchestration:

- `VoiceInputPipeline` accepts an optional `AudioRecorder`, a `SpeechToTextEngine`, a `PromptNormalizer`, and `NormalizationContext`.
- `VoiceInputPipeline.run()` preserves `Transcript`, `NormalizedPrompt`, and `PromptInsertion` stage outputs. If direct paste fails, the app fallback copies the final prompt to the pasteboard.
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
- `VoiceInputPipeline` owns record, transcribe, normalize, refine, and insertion-result orchestration.

Current test adapter:

- `MockMicrophonePermissionProvider`

Current macOS adapter:

- `AVFoundationMicrophonePermissionProvider`

## LocalAppDataStore

Current adapter:

- `LocalAppDataStore` creates the Application Support-backed repositories used by the macOS shell.

Current use cases:

- `DictionaryEntryLoadingUseCase` combines seed dictionary entries, contextual entries, and saved `LocalContextModel.postSTTEntries` for hotkey runtime normalization.
- `SpeechRecognitionHintsUseCase` converts loaded `DictionaryEntry.recognitionHints` values into bounded, de-duplicated ASR contextual strings, using `spokenForms` only as a legacy fallback.
- `LocalContextModelRebuildUseCase` runs selected learning sources and persists the rebuilt model through `LocalContextModelDataUseCase`; the macOS shell exposes model export/import/delete controls.
- `AppSettingsUseCase` owns repository path and hotkey updates so the UI does not duplicate persistence rules.

Product direction:

- The saved local context model is the primary storage mechanism for learned context.
- Learned context should be usable before STT as recognition hints and after STT as deterministic transforms.
- Model rebuild flows are explicit curation surfaces, not part of the core hotkey input path.

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

- Insert only after the user invokes or stops the voice input action.
- Never press Enter or submit the target app automatically.
- Consume `PromptInsertion.text`; ignore candidate data for insertion.
- The app layer cannot request automatic submission through `PromptInsertion`.
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

- Control-Option-Space

Current test adapter:

- `MockKeyboardShortcutMonitor`

Current macOS adapter:

- `AppKitKeyboardShortcutMonitor` in the app shell.

App shell rules:

- Control-Option-Space starts the same record/transcribe/insert path as the menu item.
- Repeated hotkey/menu triggers are ignored while a recording/transcription flow is active.

## ContextProvider

Current providers:

- `GitRepositoryContextProvider` reads git root, current branch, and a bounded list of tracked file paths through local read-only `git` commands only.
- `RepositoryVocabularyUseCase` can turn repository name, branch name, and tracked file names into dictionary entries or learning candidates.
- `RepositoryVocabularyLearningSource` adapts configured repository vocabulary into the explicit learning flow. The macOS shell does not mix repository vocabulary into the hotkey runtime dictionary.
- `JSONAppSettingsRepository` stores local app settings, including an optional repository folder override.
- `LearningSource` is the app-level interface for local learning inputs. `LocalAgentHistoryTextProvider` reads bounded local Codex and Claude history text, while repository vocabulary is another learning source.
- Generic learning-reviewer command execution is out of the MVP. Future model-assisted review must be a local Foundation Model adapter with no network IO.

Direction:

- Learning-source adapters educate a local context model from bounded local data.
- GitHub, Slack, and Chatwork adapters must read local archives, exports, caches, or checked-out files before they are added.
- Process-backed adapters must restrict themselves to local read-only commands; network-capable commands such as `git fetch`, `git pull`, and `git clone` are outside the product boundary.
- Any adapter that would require network IO is outside the product boundary.
- Local Foundation Model adapters may support model education or optional fallback conversion, but they must not upload prompts, audio, transcripts, or learned context.

Future providers:

- focused app provider,
- terminal current directory provider,
- repository vocabulary provider.
- GitHub local archive/cache learning-source provider,
- Slack local archive/cache learning-source provider,
- Chatwork local archive/cache learning-source provider,
- local Foundation Model provider.

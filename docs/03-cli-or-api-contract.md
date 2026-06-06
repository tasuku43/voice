# CLI / API contract

The production app is a macOS menu bar utility. The package also includes a small CLI demo so core behavior can be tested in CI and by coding agents.

## macOS app shell

```bash
swift run voice-agent-input-app
```

The current shell installs a menu bar item, registers the configured voice-input hotkey (default Control-Option-Space), shows a cursor-adjacent recording HUD near the focused input when possible, records while the hotkey is held, and transcribes the clip through on-device `AppleSpeechEngine`. The HUD exposes connection/listening/quiet state, live input-level feedback, elapsed time, stop control, and stop-to-paste guidance. Loaded dictionary entries expose ASR-friendly `recognitionHints`; those are converted to `SpeechRecognitionHints` and passed to Apple Speech as `contextualStrings` before the same entries are used for post-STT normalization through `spokenForms` as a fallback. Quick Paste is the only normal voice input mode: key release or the Stop button completes the user action and pastes the corrected prompt. Paste uses `PromptInsertionUseCase`; it attempts Accessibility-based Command-V paste only after that user action and falls back to copying the prompt to the pasteboard when Accessibility access is not trusted.

The shell also includes local hotkey settings, permission status display, a voice-input permission shortcut, and a `Model Education` submenu for repository-folder selection, `Rebuild Local Context Model...`, and local context model export/import/open-folder/delete controls.

Product direction: the primary app contract is hotkey dictation into the focused cursor using a local context model. `Quick Paste` is the implementation of that daily path. Model education happens through explicit local context model rebuilds, not a second voice input mode.

## Demo CLI

```bash
swift run voice-agent-input-demo "くらのコードでタイプスクリプトエラーを直して"
```

Default output is a normalization JSON object for CI stability and debugging:

```json
{
  "mode": "normalize",
  "normalization": {
    "rawText": "...",
    "correctedText": "...",
    "corrections": [...]
  }
}
```

History learning mode reports generated local context model entries without saving them:

```sh
swift run voice-agent-input-demo --mode learn-history
```

History learning output includes `historyLearning.scannedTextCount`, `historyLearning.sourceTextCounts`, `historyLearning.candidates`, and `historyLearning.skippedExistingCandidateCount`. It reads bounded local Codex/Claude-style history through `LocalAgentHistoryTextProvider`, uses the fixed user scope for generated learning entries, and does not persist local context model data.

History learning normalize mode simulates rebuilding from generated history learning entries and immediately normalizes a later utterance without writing local files:

```sh
swift run voice-agent-input-demo --mode learn-history-normalize "project specific nameの設定を直して"
```

This output includes both `historyLearning` and `normalization`, so tests and manual experiments can verify that history-derived entries would improve the next rule-based normalization step after rebuilding the local context model.

## Core API

Primary normalization use case:

```swift
PromptNormalizationUseCase.normalize(rawText: String) -> NormalizationResult
```

Insertion value:

```swift
PromptInsertion(text: String)
```

`PromptInsertion` is the normal Quick Paste output. It returns the exact text that a UI or insertion adapter may paste; it has no automatic-submit option.

Voice-input orchestration:

```swift
VoiceInputPipeline.run() async throws -> VoiceInputPipelineResult
```

This keeps audio capture behind `AudioRecorder` and STT behind `SpeechToTextEngine`, with mock adapters available for tests and the app shell wired to local AVFoundation and Apple Speech adapters. Tests can inject `MockAudioRecorder` and `MockSpeechEngine` without adding mock-only methods to the production STT protocol. Runtime entries also feed `SpeechRecognitionHints` so the saved local context model can affect recognition before post-STT normalization.

Local context model:

```swift
SpeechRecognitionHintsUseCase.hints(from entries: [DictionaryEntry]) -> SpeechRecognitionHints
DictionaryEntryLoadingUseCase.loadEntries(...) throws -> [DictionaryEntry]
LearningSource.learningTexts() throws -> [LearningText]
AgentHistoryLearningModeUseCase.generateCandidates(...) throws -> AgentHistoryLearningModeResult
```

The current concrete model is represented by dictionary entries, recognition hints, learning source text, source kind metadata, last rebuild time, and candidate metadata. `LocalContextModelRebuildUseCase.rebuild(...)` runs explicit learning sources and persists the rebuilt model through `LocalContextModelDataUseCase`. `DictionaryEntryLoadingUseCase` loads seed entries, contextual entries, and saved `LocalContextModel.postSTTEntries` for the hotkey runtime, while `JSONLocalContextModelRepository` persists the model as a first-class local document.

Insertion use case:

```swift
PromptInsertionUseCase.insert(_ prompt: PromptInsertion, afterUserAction: Bool) throws
```

Insertion requires `afterUserAction = true`. The insertion request has no automatic-submit option.

Local context model data use case:

```swift
LocalContextModelDataUseCase.exportModel() throws -> LocalContextModel
LocalContextModelDataUseCase.importModel(_ model: LocalContextModel) throws
LocalContextModelDataUseCase.rebuildModel(...) throws -> LocalContextModel
LocalContextModelDataUseCase.deleteLocalContextModel() throws
LocalContextModelRebuildUseCase.rebuild(...) throws -> LocalContextModelRebuildResult
```

These operations apply to the saved local context model document used for STT recognition hints and post-STT transforms.
The app shows rebuild metadata after an explicit model rebuild. Exported local context model documents remain inspectable JSON for deeper local data review.

App settings:

```swift
AppSettings(
    repositoryPath: String?,
    voiceInputShortcut: KeyboardShortcut
)
```

Missing settings decode to the local default Control-Option-Space voice-input hotkey. Speech currently uses the Apple Speech adapter's fixed local Japanese locale by default; this is not an app setting.

The macOS menu bar shell exposes hotkey settings locally through `Hotkey Settings...`; changing them affects later recordings only and does not upload audio or transcripts.

Runtime voice input currently stays global: repository folders do not implicitly change the dictionary used by hotkey recording, Apple Speech hints, or post-STT normalization. Repository folders are learning-source configuration, so repository context is included through explicit source selection and bounded model rebuilds rather than implicit broad scans.

Permission status use case:

```swift
PermissionStatusUseCase.currentStatus() -> PermissionStatusSnapshot
```

The macOS shell displays microphone, speech recognition, Accessibility paste, and Input Monitoring hotkey states through `Permission Status...`. It also writes these statuses to the debug log at launch, requests Input Monitoring and Accessibility access when needed, and exposes `Open Voice Input Permissions...` to open the missing macOS Privacy settings for global push-to-talk hotkeys and automatic paste. Recording and transcription permission prompts remain part of the explicit recording flow.

These APIs must remain deterministic and testable without macOS permissions.

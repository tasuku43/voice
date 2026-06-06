# CLI / API contract

The production app is a macOS menu bar utility. The package also includes a small CLI demo so core behavior can be tested in CI and by coding agents.

## macOS app shell

```bash
swift run voice-agent-input-app
```

The current shell installs a menu bar item, registers the configured voice-input hotkey (default Control-Option-Space), shows a cursor-adjacent recording HUD near the focused input when possible, records while the hotkey is held, and transcribes the clip through on-device `AppleSpeechEngine`. The HUD exposes connection/listening/quiet state, live input-level feedback, elapsed time, stop control, and stop-to-paste guidance. Loaded dictionary entries expose ASR-friendly `recognitionHints`; those are converted to tagged `SpeechRecognitionHints` and passed to Apple Speech as `AnalysisContext.contextualStrings` before the same entries are used for post-STT normalization through `spokenForms` as a fallback. Quick Paste is the only normal voice input mode: key release or the Stop button completes the user action and pastes the corrected prompt. The same post-STT `PromptTextRefiner` boundary used by `TranscribeCLI` can be enabled locally for the hotkey path with `VOICE_AGENT_INPUT_TEXT_REFINER=smooth-pauses`, `foundation-model`, or `smooth-pauses+foundation-model`; by default no Foundation Model conversion is run. Paste uses `PromptInsertionUseCase`; it attempts Accessibility-based Command-V paste only after that user action and falls back to copying the prompt to the pasteboard when Accessibility access is not trusted.

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

## Transcription CLI

```bash
swift run TranscribeCLI /path/to/audio.caf
swift run TranscribeCLI /path/to/audio.caf --locale ja-JP
swift run TranscribeCLI /path/to/audio.caf --context ./contextual-strings.json --json
swift run TranscribeCLI /path/to/audio.caf --profile transcription --expected ./expected.txt
swift run TranscribeCLI /path/to/audio.caf --context ./contextual-strings.json --corrections ./corrections.json --expected ./expected.txt
swift run TranscribeCLI --batch /path/to/testdata --profile transcription --smooth-pauses
swift run TranscribeCLI --batch /path/to/testdata --profile transcription --smooth-pauses --foundation-model
```

`TranscribeCLI` is the thin accuracy-check route for SpeechEngine itself. It calls the same `AppleSpeechEngine.transcribe(audioFile:options:)` implementation as the app, but it does not start a hotkey monitor, request Accessibility insertion, or paste into another app. If `--context` is omitted, it loads the saved local context model through the same local repository path as the app and converts entries with `SpeechRecognitionHintsUseCase`.

By default the CLI prints raw STT output. `--profile dictation|transcription` switches between the natural-dictation and raw-transcription SpeechAnalyzer modules. `--expected` compares the emitted text with a golden transcript and prints character error rate (CER), content CER, punctuation edit distance, and line-break edit distance. `--batch` evaluates subdirectories that contain `audio.wav` and `expected.txt`, then prints per-case and average distance metrics so feedback loops can compare profile/refiner choices numerically. `--normalize` explicitly runs the same deterministic dictionary normalization used by the hotkey path after STT. `--smooth-pauses` applies the local deterministic `JapanesePauseSmoothingRefiner` after normalization. `--foundation-model` applies the local Foundation Models `FoundationModelPromptTextRefiner` after deterministic normalization and any pause smoothing. `--corrections` adds bounded local correction entries for a repeatable feedback loop and implies `--normalize`; it does not change SpeechEngine behavior.

Context JSON may be either a plain tag-to-string-list object:

```json
{
  "commands": ["make check"],
  "technicalTerms": ["SpeechAnalyzer"]
}
```

or an encoded `ContextualStringsConfig`. JSON output encodes `TranscriptionResult` with `text`, `segments`, `alternatives`, and `metadata`.

Corrections JSON may be either an array of `DictionaryEntry` values or a compact local correction list:

```json
[
  {
    "spokenForms": ["CRIコマンド"],
    "canonical": "CLIコマンド",
    "kind": "command",
    "confidence": 1.0
  }
]
```

When `--expected`, `--normalize`, `--smooth-pauses`, or `--foundation-model` is used with `--json`, JSON output wraps the raw `TranscriptionResult` with optional `normalization`, `refinement`, and `evaluation` fields so the raw engine output remains inspectable.

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

This keeps audio capture behind `AudioRecorder` and STT behind `SpeechToTextEngine`, with mock adapters available for tests and the app shell wired to local AVFoundation and Apple Speech adapters. Tests can inject `MockAudioRecorder` and `MockSpeechEngine` without adding mock-only methods to the production STT protocol. Runtime entries also feed `SpeechRecognitionHints` so the saved local context model can affect recognition before post-STT normalization. Optional `PromptTextRefiner` implementations run after deterministic normalization and before insertion; this is the shared boundary for CLI file input and hotkey audio input.

Direct file transcription:

```swift
SpeechEngine.transcribe(audioFile: URL, options: TranscriptionOptions) async throws -> TranscriptionResult
```

This path is shared by `TranscribeCLI` and `AppleSpeechEngine`. Hotkey recording still uses the `SpeechToTextEngine` bridge so callers that only need final text can read `Transcript.text` or `TranscriptionResult.text`. Raw STT remains separate from deterministic prompt normalization and optional text refinement.

Shared post-STT refinement:

```swift
PromptTextRefiner.refine(_ request: PromptTextRefinementRequest) async throws -> PromptTextRefinementResult
```

`JapanesePauseSmoothingRefiner` joins obvious false sentence stops and paragraph breaks after normalization. `FoundationModelPromptTextRefiner` uses local Foundation Models only, checks `SystemLanguageModel.isAvailable`, and does not introduce network IO. The current app exposes this for local feedback through `VOICE_AGENT_INPUT_TEXT_REFINER`, while the CLI exposes it through `--smooth-pauses` and `--foundation-model`.

Local context model:

```swift
SpeechRecognitionHintsUseCase.hints(from entries: [DictionaryEntry]) -> SpeechRecognitionHints
DictionaryEntryLoadingUseCase.loadEntries(...) throws -> [DictionaryEntry]
LearningSource.learningTexts() throws -> [LearningText]
AgentHistoryLearningModeUseCase.generateCandidates(...) throws -> AgentHistoryLearningModeResult
```

The current concrete model is represented by dictionary entries, recognition hints, learning source text, source kind metadata, last rebuild time, and generation metadata. `LocalContextModelRebuildUseCase.rebuild(...)` runs explicit learning sources and persists the rebuilt model through `LocalContextModelDataUseCase`. `DictionaryEntryLoadingUseCase` loads seed entries, contextual entries, and saved `LocalContextModel.postSTTEntries` for the hotkey runtime, while `JSONLocalContextModelRepository` persists the model as a first-class local document.

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

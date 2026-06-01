# CLI / API contract

The production app will be a macOS menu bar utility. The scaffold also includes a small CLI demo so core behavior can be tested in CI and by coding agents.

## macOS app shell

```bash
swift run voice-agent-input-app
```

The current shell installs a menu bar item, registers the configured voice-input hotkey (default Control-Option-Space), shows a small recording status indicator near the focused input when possible, records either while the hotkey is held or until the toggle hotkey is pressed again, and transcribes the clip through on-device `AppleSpeechEngine`. Loaded dictionary entries expose ASR-friendly `recognitionHints`; those are converted to `SpeechRecognitionHints` and passed to Apple Speech as `contextualStrings` before the same entries are used for post-STT normalization through `spokenForms` as a fallback. In `Quick Paste` mode, key release, toggle stop, or the Stop button is explicit confirmation to paste the corrected prompt. In `Learning Preview` mode, the app opens an editable raw/corrected preview so the user can refine the prompt and generate learning candidates. Paste uses `PromptInsertionUseCase`; it attempts Accessibility-based Command-V paste only after explicit confirmation and falls back to copying the prompt to the pasteboard when Accessibility access is not trusted. If direct paste fails, the app falls back to the editable preview window before insertion.

The shell also includes a mock preview action for development, Control-Shift-V voice input history recall, local voice input mode settings, local recording settings, permission status display, a Privacy & Security settings shortcut, repository-folder selection for repository vocabulary learning, per-candidate learning approval, and export/import/open-folder/delete controls for approved local dictionary entries.

## Demo CLI

```bash
swift run voice-agent-input-demo "くらのコードでタイプスクリプトエラーを直して"
```

Default output is a preview JSON object:

```json
{
  "mode": "preview",
  "preview": {
    "rawTranscript": "...",
    "correctedPrompt": "...",
    "corrections": [...],
    "requiresExplicitConfirmation": true
  }
}
```

Confirm mode simulates the explicit-confirmation step without submitting:

```bash
swift run voice-agent-input-demo --mode confirm --edited "Claude Code で TypeScript error を直して" "くらのコードでタイプスクリプトエラーを直して"
```

Confirm output includes `confirmed.promptToInsert`, extracted learning `candidates`, and `confirmed.shouldSubmitAutomatically = false`.

History learning mode previews local dictionary candidates without approving or saving them:

```sh
swift run voice-agent-input-demo --mode learn-history --scope repository --approved-dictionary /path/to/approved-dictionary.json
```

History learning output includes `historyLearning.scannedTextCount`, `historyLearning.candidates`, and `historyLearning.skippedExistingCandidateCount`. It reads bounded local Codex/Claude-style history through `LocalAgentHistoryTextProvider`, uses the requested scope for generated candidates, skips entries already represented by the optional approved dictionary JSON, and does not persist approved dictionary entries.

History learning normalize mode simulates approving the generated history candidates and immediately normalizes a later utterance without writing local dictionary files:

```sh
swift run voice-agent-input-demo --mode learn-history-normalize --scope repository "project specific nameの設定を直して"
```

This output includes both `historyLearning` and `normalization`, so tests and manual experiments can verify that history-derived candidates would improve the next rule-based normalization step before using the app's approval UI.

## Core API

Primary use case:

```swift
PromptNormalizationUseCase.normalize(rawText: String) -> NormalizationResult
```

Preview use case:

```swift
PromptPreviewUseCase.preview(rawTranscript: String) -> PromptPreview
PromptPreviewUseCase.confirm(preview: PromptPreview, finalEditedPrompt: String?) -> ConfirmedPrompt
```

`PromptPreview` always requires explicit confirmation before insertion. `ConfirmedPrompt` returns the exact prompt text that a future UI or insertion adapter may paste, but it must not submit automatically.

Voice-input orchestration:

```swift
VoiceInputFlowUseCase.transcribeAndPreview(mockAudioText: String) async throws -> PromptPreview
VoiceInputFlowUseCase.recordTranscribeAndPreview() async throws -> PromptPreview
```

This keeps audio capture behind `AudioRecorder` and STT behind `SpeechToTextEngine`, with mock adapters available for tests and the app shell wired to local AVFoundation and Apple Speech adapters.

Learning use case:

```swift
PromptNormalizationUseCase.learn(rawText: String, autoCorrectedText: String, finalEditedText: String) -> [CorrectionCandidate]
DictionaryLearningUseCase.approveCandidates(_ candidates: [CorrectionCandidate]) throws -> [DictionaryEntry]
```

Insertion use case:

```swift
PromptInsertionUseCase.insert(_ confirmedPrompt: ConfirmedPrompt, explicitConfirmation: Bool) throws
```

Insertion requires `explicitConfirmation = true`, always passes `submitAutomatically = false` to the insertion adapter, and rejects any `ConfirmedPrompt` that requests automatic submission.

Local learning data use case:

```swift
LocalLearningDataUseCase.exportApprovedEntries() throws -> [DictionaryEntry]
LocalLearningDataUseCase.importApprovedEntries(_ entries: [DictionaryEntry], merge: Bool) throws
LocalLearningDataUseCase.deleteAllLocalLearningData() throws
```

These operations apply only to approved local dictionary entries. They do not export or persist raw audio or raw transcripts.

Voice input history:

```swift
VoiceInputHistoryUseCase.record(prompt: String) throws
VoiceInputHistoryUseCase.recentEntries() throws -> [VoiceInputHistoryEntry]
```

Voice input history stores pasted final prompts locally for recall. It does not store raw audio or raw transcripts, and it is separate from approved dictionary learning data.

Voice input mode decision:

```swift
VoiceInputModeDecisionUseCase.decide(mode: VoiceInputMode, preview: PromptPreview) -> VoiceInputModeDecision
```

`Quick Paste` returns a `ConfirmedPrompt` containing only `preview.correctedPrompt` and no learning candidates. This keeps the daily path rule-based and avoids the local learning reviewer, candidate extraction review, and candidate approval UI. `Learning Preview` returns the editable preview so user edits can generate candidates and evolve the approved dictionary.

App settings:

```swift
AppSettings(
    repositoryPath: String?,
    recordingDurationSeconds: TimeInterval,
    speechLocaleIdentifier: String,
    voiceInputMode: VoiceInputMode,
    voiceInputShortcut: KeyboardShortcut,
    voiceInputTriggerMode: VoiceInputTriggerMode,
    learningReviewerCommandPath: String?,
    learningReviewerCommandArguments: [String]
)
```

Missing settings decode to local defaults: four seconds of recording, `ja-JP` speech recognition, `Quick Paste` voice input mode, Control-Option-Space voice-input hotkey, press-and-hold trigger mode, and no learning reviewer command. Runtime use clamps recording duration to 1...30 seconds, falls back to `ja-JP` when the stored locale is blank, trims reviewer command arguments, and treats a blank reviewer command path as disabled.

The macOS menu bar shell exposes recording settings locally through `Recording Settings...` and hotkey settings through `Hotkey Settings...`; changing them affects later recordings only and does not upload audio or transcripts.

The macOS menu bar shell exposes learning reviewer command configuration through `Learning Settings...`. The command is optional and local-only. When configured, the app sends candidate-review JSON to the command only after preview confirmation; it is not part of speech recognition, dictionary normalization, or prompt refinement. The interactive app uses a short reviewer timeout so optional review cannot become a noticeable paste-confirmation bottleneck.

Learning Preview uses `AppSettings.preferredLearningScope` when confirming user edits. Runtime voice input stays global: repository folders do not implicitly change the dictionary used by hotkey recording, Apple Speech hints, or post-STT normalization. Repository folders are learning-source configuration, so approved candidates still become user-scoped entries unless a caller explicitly requests another scope.

Learning candidate review:

```swift
PromptEditLearningUseCase.confirm(preview: PromptPreview, finalEditedPrompt: String?, suggestedScope: DictionaryScope) async throws -> ConfirmedPrompt
LocalCommandLearningCandidateReviewer.review(candidates: [CorrectionCandidate], diff: PromptDiff) async throws -> [CorrectionCandidate]
```

Candidate review must preserve dangerous-command guardrails. A reviewer may update reasons and confidence, but it must not make a dangerous substitution auto-apply.

Permission status use case:

```swift
PermissionStatusUseCase.currentStatus() -> PermissionStatusSnapshot
```

The macOS shell displays microphone, speech recognition, Accessibility paste, and Input Monitoring hotkey states through `Permission Status...`. It also writes these statuses to the debug log at launch, requests Input Monitoring and Accessibility access when needed, and exposes `Open Voice Input Permissions...` to open the missing macOS Privacy settings for global push-to-talk hotkeys and automatic paste. Recording and transcription permission prompts remain part of the explicit recording flow.

These APIs must remain deterministic and testable without macOS permissions.

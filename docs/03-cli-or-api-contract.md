# CLI / API contract

The production app will be a macOS menu bar utility. The scaffold also includes a small CLI demo so core behavior can be tested in CI and by coding agents.

## macOS app shell

```bash
swift run voice-agent-input-app
```

The current shell installs a menu bar item, registers Command-Shift-Space as a voice-input hotkey, records a short microphone clip with `AVFoundationAudioRecorder`, transcribes the clip through on-device `AppleSpeechEngine`, and opens an editable preview window before insertion. Confirming the preview uses `PromptInsertionUseCase`; it attempts Accessibility-based Command-V paste only after explicit confirmation and falls back to copying the prompt to the pasteboard when Accessibility access is not trusted.

The shell also includes a mock preview action for development, local recording settings, permission status display, a Privacy & Security settings shortcut, repository-folder selection for repository-scoped vocabulary, per-candidate learning approval, and export/import/open-folder/delete controls for approved local dictionary entries.

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

App settings:

```swift
AppSettings(
    repositoryPath: String?,
    recordingDurationSeconds: TimeInterval,
    speechLocaleIdentifier: String,
    learningReviewerCommandPath: String?,
    learningReviewerCommandArguments: [String]
)
```

Missing settings decode to local defaults: four seconds of recording, `ja-JP` speech recognition, and no learning reviewer command. Runtime use clamps recording duration to 1...30 seconds, falls back to `ja-JP` when the stored locale is blank, trims reviewer command arguments, and treats a blank reviewer command path as disabled.

The macOS menu bar shell exposes these recording settings locally through `Recording Settings...`; changing them affects later recordings only and does not upload audio or transcripts.

The macOS menu bar shell exposes learning reviewer command configuration through `Learning Settings...`. The command is optional and local-only. When configured, the app sends candidate-review JSON to the command only after preview confirmation; it is not part of speech recognition, dictionary normalization, or prompt refinement. The interactive app uses a short reviewer timeout so optional review cannot become a noticeable paste-confirmation bottleneck.

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

The macOS shell displays microphone, speech recognition, and Accessibility paste states through `Permission Status...`. It only reads current adapter status; recording and transcription permission prompts remain part of the explicit recording flow.

These APIs must remain deterministic and testable without macOS permissions.

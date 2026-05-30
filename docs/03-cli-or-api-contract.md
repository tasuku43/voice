# CLI / API contract

The production app will be a macOS menu bar utility. The scaffold also includes a small CLI demo so core behavior can be tested in CI and by coding agents.

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

Mock voice-input orchestration:

```swift
VoiceInputFlowUseCase.transcribeAndPreview(mockAudioText: String) async throws -> PromptPreview
```

This keeps STT behind `SpeechToTextEngine` while allowing UI work to proceed with a mock engine before real microphone capture exists.

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

These APIs must remain deterministic and testable without macOS permissions.

# CLI / API contract

The production app will be a macOS menu bar utility. The scaffold also includes a small CLI demo so core behavior can be tested in CI and by coding agents.

## Demo CLI

```bash
swift run voice-agent-input-demo "くらのコードでタイプスクリプトエラーを直して"
```

Output is a JSON object:

```json
{
  "rawText": "...",
  "correctedText": "...",
  "corrections": [...],
  "candidates": [...]
}
```

## Core API

Primary use case:

```swift
PromptNormalizationUseCase.normalize(rawText: String) -> NormalizationResult
```

Learning use case:

```swift
PromptNormalizationUseCase.learn(rawText: String, autoCorrectedText: String, finalEditedText: String) -> [CorrectionCandidate]
```

These APIs must remain deterministic and testable without macOS permissions.

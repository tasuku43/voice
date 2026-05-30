# Architecture

## Layer diagram

```text
Future macOS UI / CLI demo
          |
          v
App use cases
          |
          v
Domain core
          ^
          |
Infra adapters
```

## Package responsibilities

### Domain

Pure types and algorithms:

- `DictionaryEntry`
- `DictionaryScope`
- `DictionaryEntryKind`
- `NormalizationEngine`
- `CorrectionCandidate`
- `CandidateExtractor`
- `PromptDiff`
- dangerous command policy

Domain must be deterministic and free of file, UI, environment, or macOS permission dependencies.

### App

Use-case orchestration:

- normalize a prompt,
- learn candidates from edits,
- combine stores and engines,
- produce results for UI or CLI.

### Infra

Adapters:

- JSON dictionary repository,
- future STT adapter,
- future pasteboard adapter,
- future git context provider.

### UI boundary

Future SwiftUI/AppKit app:

- menu bar,
- hotkey,
- preview panel,
- settings,
- candidate approval UI.

The UI must call app use cases and avoid embedding core logic.

## Dependency direction

- UI depends on App.
- App depends on Domain and protocols.
- Infra implements protocols.
- Domain depends on nothing but Foundation-level value types.

## Extension points

- Add STT engines behind `SpeechToTextEngine`.
- Add persistence behind dictionary repository protocols.
- Add context providers behind scoped vocabulary protocols.
- Add UI views without changing normalization internals.

## Anti-patterns

- UI-driven business logic.
- Unbounded repository scans.
- Silent cloud calls.
- Automatic prompt submission.
- Dangerous command substitutions with `autoApply = true`.
- Global dictionary entries for repo-specific symbols.

## Why this architecture

The product will need native macOS integration, STT adapters, local persistence, repository context, and deterministic learning. These concerns evolve independently. A layered architecture lets coding agents safely extend one area without breaking privacy, insertion safety, or dictionary behavior.

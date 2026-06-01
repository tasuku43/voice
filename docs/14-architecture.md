# Architecture

## Product layers

The product has two conceptual layers:

1. **Model education layer**: reads bounded local sources through adapters and builds a local context model.
2. **Voice input app layer**: records audio, transcribes speech, transforms text with the local model, and inserts text at the focused cursor.

The local context model is not necessarily an LLM. In the MVP it is dictionaries, recognition hints, source metadata, spoken forms, and deterministic transform rules. A local Foundation Model can be introduced later for model education and as an optional last-resort conversion stage.

## Runtime pipeline

```text
Hotkey
  -> Audio capture
  -> STT with local recognition hints
  -> Built-in developer vocabulary transform
  -> Personal context model transform
  -> Optional local Foundation Model fallback
  -> Focused cursor insertion or copy fallback
```

No stage in this pipeline may require network IO in the MVP.

## Education pipeline

```text
Codex / Claude Code local sessions
Git repository vocabulary
Future GitHub / Slack / Chatwork local adapters
Manual dictionary edits
  -> Learning source adapters
  -> Vocabulary and context extractors
  -> Local context model store
  -> STT recognition hints + post-STT transforms
```

Adapters must be bounded, local-first, and explicit about what they read.

## Package layer diagram

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
- local context model value types
- deterministic transform policies
- dangerous command policy

Domain must be deterministic and free of file, UI, environment, or macOS permission dependencies.

### App

Use-case orchestration:

- normalize a prompt,
- learn candidates from edits,
- build or load local context model data,
- choose recognition hints for STT,
- apply system vocabulary and personal context transforms,
- keep local Foundation Model fallback behind an optional protocol,
- combine stores and engines,
- produce results for UI or CLI.
- keep capture/STT stage outputs through `VoiceInputPipeline`.
- keep post-STT text processing through `PromptProcessingPipeline`.
- keep future local prompt refinement behind `PromptRefiner`.

### Infra

Adapters:

- JSON dictionary repository,
- STT adapter,
- pasteboard and Accessibility insertion adapters,
- git context provider,
- local learning source providers,
- future GitHub / Slack / Chatwork adapters,
- future local Foundation Model adapter.

Infra adapters must not introduce implicit network IO. Any future connector with network-backed data must be an explicit opt-in product decision and remain outside the MVP boundary.

### UI boundary

Future SwiftUI/AppKit app:

- menu bar,
- hotkey,
- cursor-adjacent recording HUD,
- focused cursor insertion,
- settings for hotkey, STT locale, learning sources, and local data controls,
- optional preview fallback panel.

The UI must call app use cases and avoid embedding core logic.

## Dependency direction

- UI depends on App.
- App depends on Domain and protocols.
- Infra implements protocols.
- Domain depends on nothing but Foundation-level value types.

## Extension points

- Add STT engines behind `SpeechToTextEngine`.
- Add recognition-hint builders from the local context model.
- Add local prompt cleanup behind `PromptRefiner`; `NoOpPromptRefiner` is the default.
- Add persistence behind dictionary repository protocols.
- Add context providers behind scoped vocabulary and learning-source protocols.
- Add local Foundation Model transforms behind optional protocols.
- Add UI views without changing normalization internals.

## Component Contracts

Short component contracts live in `docs/contracts/`:

- speech-to-text,
- local-context-model,
- normalization,
- prompt-refinement,
- voice-input-pipeline,
- preview-and-approval,
- learning,
- output.

Focused future Codex prompts live in `docs/codex-sessions/` so a session can improve one component without rereading the whole repository. The local context model session is the preferred starting point for work that changes how learning sources become recognition hints or post-STT transforms.

## Anti-patterns

- UI-driven business logic.
- Unbounded repository scans.
- Silent cloud calls.
- Network IO in the MVP voice input, model education, or fallback conversion paths.
- Using an LLM as the default hotkey conversion path.
- Automatic prompt submission.
- Dangerous command substitutions with `autoApply = true`.
- Global dictionary entries for repo-specific symbols.

## Why this architecture

The product will need native macOS integration, STT adapters, local persistence, repository context, chat and agent-history adapters, deterministic learning, and eventually local Foundation Model support. These concerns evolve independently. A layered architecture lets coding agents safely extend one area without breaking privacy, insertion behavior, or dictionary behavior.

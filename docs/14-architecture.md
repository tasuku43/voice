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
Future GitHub / Slack / Chatwork local archive/cache adapters
  -> Learning source adapters
  -> Vocabulary and context extractors
  -> Local context model store
  -> STT recognition hints + post-STT transforms
```

Adapters must be bounded, local-first, and explicit about what they read.

## Package layer diagram

```text
macOS menu bar app / CLI demo
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
- local context model value types
- deterministic transform policies

Domain must be deterministic and free of file, UI, environment, or macOS permission dependencies.

### App

Use-case orchestration:

- normalize a prompt,
- build candidates from bounded local learning sources,
- build or load local context model data,
- choose recognition hints for STT,
- apply system vocabulary and personal context transforms,
- combine stores and engines,
- produce results for UI or CLI.
- keep capture/STT stage outputs through `VoiceInputPipeline`.
- keep post-STT text processing through `PromptProcessingPipeline`.
- keep any future local Foundation Model conversion behind an explicit optional fallback protocol.

### Infra

Adapters:

- STT adapter,
- pasteboard and Accessibility insertion adapters,
- git context provider,
- local learning source providers,
- deferred GitHub / Slack / Chatwork local archive/cache adapters,
- deferred local Foundation Model adapter.

Infra adapters must not introduce network IO. GitHub, Slack, Chatwork, and similar learning sources must be represented as local archives, exports, caches, or checked-out files before this app reads them. Process-backed adapters are limited to local read-only commands; network-capable operations such as `git fetch`, `git pull`, and `git clone` are excluded.

### UI boundary

Current AppKit menu bar app:

- menu bar,
- hotkey,
- cursor-adjacent recording HUD,
- focused cursor insertion,
- settings for hotkey, learning sources, and local data controls,
- pasteboard copy fallback.

The UI must call app use cases and avoid embedding core logic.

## Dependency direction

- UI depends on App.
- App depends on Domain and protocols.
- Infra implements protocols.
- Domain depends on nothing but Foundation-level value types.

## Extension points

- Add STT engines behind `SpeechToTextEngine`.
- Add recognition-hint builders from the local context model.
- Add local Foundation Model conversion only behind an explicit optional fallback protocol.
- Add persistence behind dictionary repository protocols.
- Add context providers behind scoped vocabulary and learning-source protocols.
- Add UI views without changing normalization internals.

## Component Contracts

Short component contracts live in `docs/contracts/`:

- speech-to-text,
- local-context-model,
- normalization,
- voice-input-pipeline,
- pasteboard fallback,
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

The product combines native macOS integration, STT adapters, local persistence, repository context, agent-history adapters, and deterministic learning. Deferred chat/archive adapters and local Foundation Model support must evolve behind the same boundaries. A layered architecture lets coding agents safely extend one area without breaking privacy, insertion behavior, or dictionary behavior.

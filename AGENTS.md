# AGENTS.md

## Project

`voice-agent-input` is a macOS-native hotkey voice input application for developer text fields.

The product goal is not to replace macOS Dictation directly. The goal is to convert spoken Japanese / mixed Japanese-English developer instructions into accurate text for tools such as Codex, Claude Code, Cursor, terminal-based coding agents, IDE assistants, Slack, Chatwork, and browser text fields by using a local context model built from the user's environment.

## Product boundary

Build a local-first desktop utility that:

- captures voice input on macOS,
- transcribes speech,
- uses local context model recognition hints during STT when supported,
- applies deterministic system dictionary and custom local context model transforms,
- inserts corrected text at the focused cursor after the user stops the hotkey recording,
- falls back to pasteboard copy or an editable preview only when direct paste cannot complete,
- educates the local context model from explicit bounded local sources such as Codex / Claude Code histories and Git repository vocabulary.

The app must run fully locally. Do not build a cloud service, browser extension, full IME, meeting recorder, autonomous code executor, network-backed STT, network-backed LLM, transcript upload path, or cloud sync unless explicitly asked.

If LLM-style assistance is introduced, it must be a local Foundation Model adapter. It may help model education, and may be used as an explicit last-resort conversion fallback only after deterministic transforms are insufficient. It must not introduce network IO and must not be the default hotkey path.

## Architecture

Maintain this dependency direction:

```text
UI / App boundary -> app use cases -> domain core
                             ^
                             |
                       infra adapters
```

Responsibilities:

- `src/VoiceAgentInputCore/Domain`: pure domain types and deterministic algorithms.
- `src/VoiceAgentInputCore/App`: use-case orchestration and result shapes.
- `src/VoiceAgentInputCore/Infra`: filesystem or framework adapters behind protocols.
- Future macOS app target: AppKit / SwiftUI shell only. Keep UI thin.

Forbidden dependencies:

- Domain must not read files, call macOS permissions, parse CLI flags, or know about UI.
- UI must not contain dictionary learning logic.
- STT must be behind a protocol.
- Persistence must be behind an adapter.

## MVP behavior

The first working app should support:

1. User invokes a hotkey.
2. App records microphone input.
3. App transcribes speech.
4. App passes local context model hints to STT when supported.
5. App applies deterministic dictionary and local context model normalization.
6. App inserts corrected text at the focused cursor when the user releases or stops recording.
7. App copies to the pasteboard if direct paste cannot complete.
8. User can explicitly rebuild the local context model from selected local learning sources.
9. Later voice input reuses the rebuilt local context model as STT hints and post-STT transforms.

Do not implement real-time character-by-character insertion in the MVP.

## Test and eval rules

Tests are the control system, not cleanup.

For each behavior change, add or update at least one of:

- unit test,
- use-case test,
- infra adapter test,
- E2E test,
- fixture-driven eval case,
- golden snapshot.

Run `make check` before finishing. If a command cannot run in the current environment, state the exact reason.

## Non-goals

Do not implement:

- full IME replacement,
- App Store packaging,
- cloud sync,
- team dictionary sharing,
- meeting recording,
- system audio capture,
- speaker diarization,
- automatic sending or submission,
- LLM-based autonomous code editing inside this app,
- cloud STT,
- network-backed LLM calls,
- transcript upload,
- preview-first candidate approval UI.

## Privacy requirements

Default behavior:

- Do not persist raw audio.
- Do not upload audio or transcripts.
- Do not persist raw transcripts unless the user enables it.
- Persist the local context model and app settings locally.
- Persist generated candidates only as part of explicit local context model rebuild data.
- Provide export/import and delete-all-local-learning-data paths.

## Change checklist

Before finishing a task:

1. Preserve architecture boundaries.
2. Keep data local.
3. Add or update tests/evals.
4. Run `make check`.
5. Update docs if behavior or contracts changed.
6. Summarize files changed, tests run, limitations, and next recommended task.

## Anti-patterns

Avoid:

- dumping logic into one large AppDelegate or view,
- coupling UI to STT directly,
- silent automatic prompt submission,
- storing raw audio by default,
- network IO in voice input, model education, or fallback conversion,
- uncontrolled recursive repo scans,
- using LLM rewriting as the default hotkey conversion path,
- auto-applying dangerous command substitutions.

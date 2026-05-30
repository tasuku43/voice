# AGENTS.md

## Project

`voice-agent-input` is a macOS-native voice input application for coding-agent prompts.

The product goal is not to replace macOS Dictation directly. The goal is to convert spoken Japanese / mixed Japanese-English developer instructions into clean, agent-ready prompts for tools such as Codex, Claude Code, Cursor, terminal-based coding agents, and IDE assistants.

## Product boundary

Build a local-first desktop utility that:

- captures voice input on macOS,
- transcribes speech,
- normalizes developer terminology,
- shows a preview before insertion,
- learns dictionary candidates from user edits,
- stores approved dictionaries locally,
- inserts the corrected prompt only after explicit confirmation.

Do not build a cloud service, browser extension, full IME, meeting recorder, or autonomous code executor unless explicitly asked.

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
4. App applies deterministic dictionary normalization.
5. App shows raw transcript and corrected prompt.
6. User may edit the corrected prompt.
7. User confirms paste.
8. App extracts dictionary candidates from the edit.
9. User approves or rejects candidates.

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
- cloud STT or transcript upload.

## Privacy requirements

Default behavior:

- Do not persist raw audio.
- Do not upload audio or transcripts.
- Do not persist raw transcripts unless the user enables it.
- Persist approved dictionary entries.
- Persist candidates only as needed for local learning.
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
- uncontrolled recursive repo scans,
- broad semantic rewriting before dictionary learning works,
- auto-applying dangerous command substitutions.

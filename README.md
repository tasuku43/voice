# voice-agent-input

A macOS-native, fully local voice input utility for developers who want hotkey dictation that understands their own coding environment.

This project is optimized for users who speak Japanese or mixed Japanese-English instructions into Codex, Claude Code, Cursor, terminal-based coding agents, IDE assistants, chat tools, and other developer surfaces. It is not trying to replace macOS Dictation wholesale. Its differentiator is a local context model built from the user's environment, then reused as STT recognition hints and deterministic post-STT transforms so focused text fields receive more accurate developer text.

## What it solves

Standard dictation converts speech into general text. Coding-agent work needs more:

- developer terminology correction: Claude Code, Codex, TypeScript, pnpm, MCP
- project-specific vocabulary: repo names, branch names, file names, symbols, product terms
- environment-specific language from Codex / Claude Code history, Git / GitHub, Slack, Chatwork, and future local adapters
- STT `contextualStrings` / recognition hints before transcription
- deterministic system and personal transforms after transcription
- local-only model education with no transcript or audio upload
- optional local Foundation Model use for model education and last-resort conversion only

## Core workflows

### Voice input

1. Press a global hotkey.
2. Record speech.
3. Transcribe the audio.
4. Apply built-in developer vocabulary.
5. Apply the user's local context model.
6. Use a local Foundation Model only when deterministic transforms are insufficient and the user has enabled that fallback.
7. Insert the corrected transcript at the focused cursor or copy it when direct paste is unavailable.

### Model education

1. Connect local learning sources through adapters.
2. Extract vocabulary, phrases, identifiers, and likely recognition hints.
3. Store the learned context model locally.
4. Reuse the model for both STT hints and post-STT transforms.

The current scaffold implements the testable core: dictionary models, normalization, local learning sources, candidate extraction, JSON persistence, fixtures, evals, and agent instructions. A first Apple Speech adapter exists behind the replaceable STT protocol.

The current app shell includes a minimal macOS menu bar executable with a configurable global voice-input hotkey (default Control-Option-Space), press-and-hold or toggle recording triggers, AVFoundation microphone recording, configurable recording duration and Speech locale, permission status display, Privacy & Security settings shortcut, on-device Apple Speech transcription, preview window, Accessibility-based paste, pasteboard fallback, per-candidate local dictionary approval, local dictionary export/import/delete/open-folder actions, and simple in-progress state for the recording flow.
The menu can store a local repository folder path for repository-scoped vocabulary when the app is launched outside a terminal. Repository context includes the git root, current branch, and a bounded set of tracked file names.

## Stack

- Swift Package Manager
- Swift 6-compatible source
- Foundation-only core for portable tests
- Future macOS app shell: SwiftUI + AppKit
- STT adapters: Apple Speech first; local-only WhisperKit or Foundation Model fallback later if needed
- Local persistence: JSON first, SQLite later if needed

## Build and test

```bash
make check
```

Equivalent raw commands:

```bash
swift test
swift run voice-agent-input-demo
```

## Demo

```bash
swift run voice-agent-input-demo "くらのコードでタイプスクリプトエラーを直して"
```

Expected output demonstrates deterministic normalization using seed entries such as Claude Code and TypeScript.

## Hand this project to a coding agent

After extracting the ZIP, start with:

```bash
make goal
```

Then paste the printed prompt into Codex. The same prompt is stored at:

```text
.codex/goals/voice-agent-input-full-build.md
docs/11-first-codex-prompt.md
```

## Development commands

```bash
make test        # run Swift tests
make eval        # run tests including fixture-driven evals
make check       # one-command validation, including app bundle smoke, MVP, privacy, and checklist contracts
make goal        # print the first autonomous Codex prompt
make manual-e2e-report  # create a dated manual macOS MVP report from the template
make validate-manual-e2e-report REPORT=test/e2e/reports/<report>.md
swift run voice-agent-input-app  # launch minimal menu bar shell
open .build/VoiceAgentInput.app  # launch bundled app with microphone and speech usage descriptions after make check
```

Use the menu bar `Hotkey Settings...` item to change the voice-input key, modifiers, and press-and-hold versus toggle recording behavior locally. Use `Recording Settings...` to change recording duration or Speech locale. Use `Permission Status...` to inspect microphone, speech recognition, and Accessibility paste states before a real recording run, and `Open Privacy Settings...` to jump to macOS privacy controls. Settings, approved dictionary entries, local context model data, and repository path are stored under Application Support; `Open Local Data Folder...` reveals that location for manual privacy checks. Raw audio is temporary and raw transcripts are not persisted by default.

Manual macOS MVP verification lives at `test/e2e/manual-macos-mvp-checklist.md`.
The current completion evidence and remaining manual proof are tracked in `docs/15-mvp-completion-audit.md`.

Component contracts live under `docs/contracts/`, and short next-session prompts live under `docs/codex-sessions/`. Use those when continuing focused work on speech, normalization, prompt refinement, repository vocabulary, preview UI, learning, or output.

## Product boundary

In scope for the first real build:

- macOS menu bar app
- hotkey-triggered voice input into the focused cursor
- local STT with recognition hints
- built-in developer vocabulary transforms
- personal context model transforms
- learning-source adapters for local developer context
- repository, history, and chat vocabulary extraction through bounded adapters
- local Foundation Model support only for model education and optional last-resort conversion
- local-only data storage

Out of scope for MVP:

- full IME replacement
- meeting recording
- system audio capture
- cloud sync
- cloud STT or transcript upload
- automatic prompt submission
- automatic command execution
- team dictionary sharing

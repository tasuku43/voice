# voice-agent-input

A macOS-native voice input scaffold for turning spoken developer instructions into clean, coding-agent-ready prompts.

This project is optimized for a user who talks to Codex, Claude Code, Cursor, terminal-based coding agents, or IDE assistants. It is not trying to replace macOS Dictation directly. Its differentiator is a local dictionary-learning and prompt-normalization layer that learns terms from corrections and repository context.

## What it solves

Standard dictation converts speech into general text. Coding-agent work needs more:

- developer terminology correction: Claude Code, Codex, TypeScript, pnpm, MCP
- project-specific vocabulary: repo names, file names, symbols, product terms
- preview-before-paste safety
- local dictionary learning from user edits
- scoped dictionaries: global, user, repository, session
- deterministic and explainable corrections
- repository context hooks for git root, branch, and tracked file-name vocabulary

## Core workflows

1. Press a global hotkey.
2. Record speech.
3. Transcribe the audio.
4. Normalize developer terms and project vocabulary.
5. Show raw transcript and corrected prompt in a preview panel.
6. Allow the user to edit before insertion.
7. Paste only after explicit confirmation.
8. Learn dictionary candidates from the raw transcript, auto-corrected prompt, and final edited prompt.

The current scaffold implements the testable core: dictionary models, normalization, candidate extraction, JSON persistence, fixtures, evals, and agent instructions. A first Apple Speech adapter exists behind the replaceable STT protocol.

The current app shell includes a minimal macOS menu bar executable with a Command-Shift-Space hotkey trigger, AVFoundation microphone recording, configurable recording duration and Speech locale, permission status display, Privacy & Security settings shortcut, on-device Apple Speech transcription, preview window, Accessibility-based paste, pasteboard fallback, per-candidate local dictionary approval, local dictionary export/import/delete/open-folder actions, and simple in-progress state for the recording flow.
The menu can store a local repository folder path for repository-scoped vocabulary when the app is launched outside a terminal. Repository context includes the git root, current branch, and a bounded set of tracked file names.

## Stack

- Swift Package Manager
- Swift 6-compatible source
- Foundation-only core for portable tests
- Future macOS app shell: SwiftUI + AppKit
- STT adapters: Apple Speech first; WhisperKit optional fallback later
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

Use the menu bar `Recording Settings...` item to change recording duration or Speech locale locally. Use `Permission Status...` to inspect microphone, speech recognition, and Accessibility paste states before a real recording run, and `Open Privacy Settings...` to jump to macOS privacy controls. Settings, approved dictionary entries, and repository path are stored under Application Support; `Open Local Data Folder...` reveals that location for manual privacy checks. Raw audio is temporary and raw transcripts are not persisted by default.

Manual macOS MVP verification lives at `test/e2e/manual-macos-mvp-checklist.md`.
The current completion evidence and remaining manual proof are tracked in `docs/15-mvp-completion-audit.md`.

Component contracts live under `docs/contracts/`, and short next-session prompts live under `docs/codex-sessions/`. Use those when continuing focused work on speech, normalization, prompt refinement, repository vocabulary, preview UI, learning, or output.

## Product boundary

In scope for the first real build:

- macOS menu bar app
- preview-before-paste workflow
- dictionary normalization
- local candidate learning
- repository context extraction
- local-only data storage

Out of scope for MVP:

- full IME replacement
- meeting recording
- system audio capture
- cloud sync
- automatic prompt submission
- automatic command execution
- team dictionary sharing

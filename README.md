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

## Core workflows

1. Press a global hotkey.
2. Record speech.
3. Transcribe the audio.
4. Normalize developer terms and project vocabulary.
5. Show raw transcript and corrected prompt in a preview panel.
6. Allow the user to edit before insertion.
7. Paste only after explicit confirmation.
8. Learn dictionary candidates from the raw transcript, auto-corrected prompt, and final edited prompt.

The current scaffold implements the testable core: dictionary models, normalization, candidate extraction, JSON persistence, fixtures, evals, and agent instructions. macOS microphone recording and real STT adapters are intentionally represented as documented next steps.

The current app shell includes a minimal macOS menu bar executable with a mock preview window, Command-Shift-Space hotkey trigger, pasteboard insertion, and local approval of dictionary candidates. It does not record real audio yet.

## Stack

- Swift Package Manager
- Swift 6-compatible source
- Foundation-only core for portable tests
- Future macOS app shell: SwiftUI + AppKit
- Future STT adapters: Apple SpeechAnalyzer / SpeechTranscriber first; WhisperKit optional fallback
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
make check       # one-command validation
make goal        # print the first autonomous Codex prompt
swift run voice-agent-input-app  # launch minimal menu bar shell
```

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

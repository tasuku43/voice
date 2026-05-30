# Full product backlog

## Core

- Improve phrase alignment in candidate extraction.
- Add confidence accumulation for repeated corrections.
- Add repository-scoped candidate promotion rules.
- Add dictionary import/export tests.
- Add golden snapshots for demo CLI output.

## macOS app

- Menu bar app shell.
- Floating preview panel.
- Keyboard shortcuts for paste/cancel/toggle.
- Candidate approval UI.
- Settings screen for privacy and retention.

## Input and insertion

- Global hotkey.
- Press-and-hold recording.
- Pasteboard insertion.
- Accessibility insertion fallback.
- Permission onboarding.

## Speech

- Audio recorder abstraction.
- Apple Speech adapter.
- Availability and locale checks.
- WhisperKit fallback investigation.

## Context

- Focused app detection.
- Terminal working directory detection.
- Git root and branch detection.
- Repository vocabulary extraction.
- Bounded scanning and ignore rules.

## Persistence

- JSON dictionary storage.
- SQLite migration if needed.
- Export/import UI.
- Delete local learning data.

## Evals

- Add real utterance fixtures.
- Add dangerous command cases.
- Add project-specific symbol cases.
- Add mixed Japanese-English prompts.

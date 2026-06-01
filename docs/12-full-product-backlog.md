# Full product backlog

## Core

- Add a rebuild-only local context model command that does not enter candidate approval.
- Add stale-model and last-rebuilt metadata to the local context model document.
- Split built-in vocabulary transforms from personal context transforms.
- Improve phrase alignment in candidate extraction.
- Add confidence accumulation for repeated corrections.
- Add repository-scoped candidate promotion rules.
- Add golden snapshots for demo CLI output.

## macOS app

- Menu bar app shell.
- Cursor-adjacent recording HUD.
- Settings screen for hotkey, STT locale, learning sources, local data, and optional fallback conversion.
- Optional floating preview panel.
- Optional candidate approval UI.

## Input and insertion

- Global hotkey.
- Press-and-hold recording.
- Pasteboard insertion.
- Accessibility insertion fallback.
- Permission onboarding.
- Copy fallback when direct insertion is unavailable.

## Speech

- Audio recorder abstraction.
- Apple Speech adapter.
- Availability and locale checks.
- Local-only WhisperKit fallback investigation.
- Local Foundation Model conversion fallback investigation after deterministic transforms prove insufficient.

## Context

- Codex / Claude Code local history adapter.
- Focused app detection.
- Terminal working directory detection.
- Git root and branch detection.
- Repository vocabulary extraction.
- GitHub learning-source adapter.
- Slack learning-source adapter.
- Chatwork learning-source adapter.
- Bounded scanning and ignore rules.

## Persistence

- JSON dictionary storage.
- Local context model storage. Initial JSON repository exists.
- SQLite migration if needed.
- Export/import UI for learned context.
- Delete local learning data.

## Evals

- Add real utterance fixtures.
- Add dangerous command cases.
- Add project-specific symbol cases.
- Add mixed Japanese-English prompts.
- Add learning-source adapter fixtures.
- Add recognition-hint generation fixtures.

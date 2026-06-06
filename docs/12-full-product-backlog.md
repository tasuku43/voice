# Product backlog

## Core

- Split built-in vocabulary transforms from personal context transforms.
- Improve phrase alignment in local context learning-entry generation.
- Add confidence accumulation for repeated local learning-source evidence.
- Add repository-scoped learning-entry promotion rules.
- Add golden snapshots for demo CLI output.

## macOS app

- Harden focused-app and caret-adjacent recording behavior.
- Keep settings limited to hotkey, local learning sources, local data controls, and explicit fallback configuration.

## Speech

- Availability and locale checks.
- Local-only WhisperKit fallback investigation.
- Local Foundation Model conversion after deterministic transforms prove insufficient; it must be explicitly enabled, local-only, and measured against deterministic smoothing before becoming a default.

## Context

- Focused app detection.
- Terminal working directory detection.
- GitHub local archive/cache learning-source adapter.
- Slack local archive/cache learning-source adapter.
- Chatwork local archive/cache learning-source adapter.
- Bounded scanning and ignore rules.

## Persistence

- SQLite migration if needed.

## Evals

- Add real utterance fixtures.
- Add dangerous command cases.
- Add project-specific symbol cases.
- Add mixed Japanese-English prompts.
- Add learning-source adapter fixtures.
- Add recognition-hint generation fixtures.

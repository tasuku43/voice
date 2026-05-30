# Implementation plan

## Phase 1: core engine

- Dictionary model.
- Scope precedence.
- Normalization pipeline.
- Candidate extraction.
- JSON persistence.
- Unit tests and evals.

## Phase 2: macOS shell

- Menu bar app. Minimal mock shell done.
- Floating preview panel. Minimal editable mock preview done.
- Mock STT integration. Done in App use case; shell records audio but still uses a mock STT transcript pending Apple Speech.
- Confirm-before-paste flow.

## Phase 3: input loop

- Global hotkey. Initial AppKit global/local monitor done for Command-Shift-Space.
- Pasteboard insertion. Done for text-only adapter and wired into the app shell.
- Accessibility permission messaging.
- Explicit no-submit behavior.

## Phase 4: real audio and STT

- Audio recorder abstraction. Done as protocol plus mock recorder.
- AVFoundation microphone recorder. Initial adapter done; it uses a temporary local file and deletes it after reading audio data.
- Apple Speech adapter.
- Availability guards.
- Mock engine retained for tests.

## Phase 5: learning loop

- Editable prompt preview.
- Diff extraction.
- Candidate approval UI. Minimal app-shell approval dialog done.
- Local dictionary persistence. JSON-backed Application Support store done.

## Phase 6: repository context

- Git root and branch detection.
- Bounded vocabulary extraction.
- Repository-scoped suggestions.

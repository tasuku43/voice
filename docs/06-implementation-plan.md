# Implementation plan

## Phase 1: core engine

- Dictionary model.
- Scope precedence.
- Normalization pipeline.
- Candidate extraction.
- JSON persistence.
- Unit tests and evals.

## Phase 2: macOS shell

- Menu bar app.
- Floating preview panel.
- Mock STT integration.
- Confirm-before-paste flow.

## Phase 3: input loop

- Global hotkey.
- Pasteboard insertion.
- Accessibility permission messaging.
- Explicit no-submit behavior.

## Phase 4: real audio and STT

- Audio recorder abstraction.
- Apple Speech adapter.
- Availability guards.
- Mock engine retained for tests.

## Phase 5: learning loop

- Editable prompt preview.
- Diff extraction.
- Candidate approval UI.
- Local dictionary persistence.

## Phase 6: repository context

- Git root and branch detection.
- Bounded vocabulary extraction.
- Repository-scoped suggestions.

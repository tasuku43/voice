# Preview Fallback Session

Purpose: improve the fallback preview shown only when direct paste cannot complete.

Read:
- `docs/contracts/preview-fallback.md`
- `src/VoiceAgentInputCore/App/PromptPreviewUseCase.swift`
- `src/VoiceAgentInputApp/PreviewWindowController.swift`

May touch:
- Preview fallback UI and preview use-case tests.

Avoid:
- Speech engines, normalization algorithms, output internals.

Contract:
- Quick Paste remains the primary path.
- Fallback preview may show raw/corrected text and accept edits.
- Paste only after the user presses Paste in the fallback preview.
- No automatic submit.
- No local context model training from edits.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testPreviewFallbackBuildsPromptInsertionText`
- `make check`

Done:
- User can inspect and edit only in the fallback path.

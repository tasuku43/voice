# Preview UI Session

Purpose: improve raw/corrected/refined prompt preview and user approval UX.

Read:
- `docs/contracts/preview-and-approval.md`
- `src/VoiceAgentInputCore/App/PromptPreviewUseCase.swift`
- `src/VoiceAgentInputApp/PreviewWindowController.swift`
- `src/VoiceAgentInputApp/CandidateApprovalDialogController.swift`

May touch:
- Preview UI, candidate approval UI, and preview use-case tests.

Avoid:
- Speech engines, normalization algorithms, output internals.

Contract:
- Show before insertion.
- Confirm before paste.
- No automatic submit.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testPreviewRequiresExplicitConfirmationBeforeInsertion`
- `make check`

Done:
- User can inspect and edit before insertion.

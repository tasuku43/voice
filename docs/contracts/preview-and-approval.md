# Preview And Approval Contract

## Inputs
- Raw transcript.
- Corrected or refined prompt.
- Corrections and candidate suggestions.

## Outputs
- `ConfirmedPrompt`
- Final edited text.
- Candidate approval choices.

## Allowed
- Show raw and corrected text.
- Accept user edits.
- Ask for candidate approval.

## Forbidden
- Speech recognition.
- Dictionary correction itself.
- LLM refinement itself.
- Automatic submit or command execution.

## Read First
- `src/VoiceAgentInputCore/App/PromptPreviewUseCase.swift`
- `src/VoiceAgentInputApp/PreviewWindowController.swift`
- `src/VoiceAgentInputApp/CandidateApprovalDialogController.swift`

## May Touch
- Preview window UI, candidate approval UI, and preview use case.

## Avoid Touching
- Speech and repository vocabulary adapters.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testPreviewRequiresExplicitConfirmationBeforeInsertion`
- `make check`

## Done
- Paste requires explicit confirmation.
- Candidate approval remains user-driven.

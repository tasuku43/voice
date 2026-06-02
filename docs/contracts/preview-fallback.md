# Preview Fallback Contract

Preview fallback is an optional safety surface when direct paste cannot be completed. It helps inspect and edit the corrected prompt, but it is not the primary hotkey dictation path and does not train the local context model.

## Inputs
- Raw transcript.
- Corrected or refined prompt.
- Corrections.

## Outputs
- `PromptInsertion`
- Final edited text.

## Allowed
- Show raw and corrected text.
- Accept user edits.

## Forbidden
- Speech recognition.
- Dictionary correction itself.
- LLM refinement itself.
- Automatic submit or command execution.
- Candidate approval UI.

## Read First
- `src/VoiceAgentInputCore/App/PromptPreviewUseCase.swift`
- `src/VoiceAgentInputApp/PreviewWindowController.swift`

## May Touch
- Preview fallback UI and preview use case.

## Avoid Touching
- Speech and repository vocabulary adapters.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testPreviewFallbackBuildsPromptInsertionText`
- `make check`

## Done
- Paste requires a completed user action when this optional workflow is used.
- Preview fallback does not open candidate approval.

# Output Contract

## Inputs
- User-confirmed final prompt.
- Output target settings or adapter.

## Outputs
- Success or failure result.

## Allowed
- Put the confirmed prompt on the pasteboard.
- Send paste when Accessibility is trusted.
- Fall back to asking the user to press Command-V.

## Forbidden
- Speech recognition.
- Dictionary correction.
- Prompt refinement.
- Learning.
- Automatic submit or command execution.

## Read First
- `src/VoiceAgentInputCore/App/PromptInsertionUseCase.swift`
- `src/VoiceAgentInputCore/Infra/AccessibilityTextInsertionController.swift`

## May Touch
- Text insertion adapters and output tests.

## Avoid Touching
- Speech, normalization, and learning logic.

## Tests
- `swift test --filter PasteboardInsertionTests`
- `make check`

## Done
- Output inserts text only after explicit confirmation.
- Automatic submit remains rejected.

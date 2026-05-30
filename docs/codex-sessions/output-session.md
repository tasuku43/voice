# Output Session

Purpose: improve confirmed prompt insertion and paste fallback behavior.

Read:
- `docs/contracts/output.md`
- `src/VoiceAgentInputCore/App/PromptInsertionUseCase.swift`
- `src/VoiceAgentInputCore/Infra/AccessibilityTextInsertionController.swift`

May touch:
- Output adapters and paste tests.

Avoid:
- Speech, normalization, prompt refinement, learning.

Contract:
- Insert only confirmed text.
- Never submit automatically.

Tests:
- `swift test --filter PasteboardInsertionTests`
- `make check`

Done:
- Accessibility paste and pasteboard fallback remain explicit and tested.

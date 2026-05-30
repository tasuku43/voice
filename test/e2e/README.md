# E2E tests

E2E coverage should exercise the real app or demo CLI path.

Current process-level coverage lives in `DemoCLITests` and runs the built `voice-agent-input-demo` executable for:

- preview mode,
- confirm mode,
- explicit no-submit behavior,
- candidate extraction from an edited prompt.

Current automated coverage builds the menu bar app bundle and validates the source-level app contract for the menu, hotkey, on-device Apple Speech wiring, preview-before-paste, candidate approval, and local dictionary data controls. Manual macOS E2E should still verify microphone permission prompts, real speech transcription, Accessibility paste into another app, and the export/import/delete menu actions.

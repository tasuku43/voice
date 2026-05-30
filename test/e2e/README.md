# E2E tests

E2E coverage should exercise the real app or demo CLI path.

Manual macOS MVP coverage is specified in `manual-macos-mvp-checklist.md`. Use `make manual-e2e-report` to create a dated report under `test/e2e/reports/` from `manual-macos-mvp-report-template.md`, then fill it in while running the checklist. Use `make validate-manual-e2e-report REPORT=test/e2e/reports/<report>.md` after the run to catch placeholders, failures, or missing metadata. `make check` validates that the checklist, report template, report-creation command, and report validator continue to cover the critical MVP flows, while a human still needs to run the checklist in a real desktop session for microphone, Apple Speech, and Accessibility behavior.

Current process-level coverage lives in `DemoCLITests` and runs the built `voice-agent-input-demo` executable for:

- preview mode,
- confirm mode,
- explicit no-submit behavior,
- candidate extraction from an edited prompt.

Current automated coverage builds the menu bar app bundle and validates the source-level app contract for the menu, hotkey, local recording settings, permission status display, on-device Apple Speech wiring, preview-before-paste, candidate approval, and local dictionary data controls. Manual macOS E2E should still verify microphone permission prompts, real speech transcription, Accessibility paste into another app, recording setting changes, permission status values, local learning, repository vocabulary, privacy expectations, and the export/import/delete menu actions.

`make check` also smoke-launches `.build/VoiceAgentInput.app` to catch immediate startup crashes. This does not replace the manual checklist because it does not interact with macOS permission prompts, menu items, microphone input, or target-app paste behavior.

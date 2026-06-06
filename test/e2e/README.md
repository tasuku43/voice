# E2E tests

E2E coverage should exercise the real app or demo CLI path.

Manual macOS MVP coverage is specified in `manual-macos-mvp-checklist.md`. Use `make manual-e2e-report` to create a dated report under `test/e2e/reports/` from `manual-macos-mvp-report-template.md`, then fill it in while running the checklist. Launch the app with `make manual-e2e-launch` or `open -n .build/VoiceAgentInput.app --args --debug` so `~/Library/Logs/VoiceAgentInput/debug.log` captures Quick Paste evidence such as `mode=quickPaste`. Run `python3 scripts/summarize_debug_log.py` after the Quick Paste checks to summarize the mode lines for the report. Run `make manual-e2e-privacy-inspect` after the privacy checks to scan `~/Library/Application Support/VoiceAgentInput` and the debug log for raw audio or raw transcript artifacts. Use `make validate-manual-e2e-report REPORT=test/e2e/reports/<report>.md` after the run to catch placeholders, failures, missing metadata, or missing Quick Paste/privacy evidence. `make check` validates that the checklist, report template, report-creation command, debug launch helper, privacy inspection helper, and report validator continue to cover the critical MVP flows, while a human still needs to run the checklist in a real desktop session for microphone, Apple Speech, and Accessibility behavior.

Current process-level coverage lives in `DemoCLITests` and runs the built `voice-agent-input-demo` executable for:

- local history-learning entry output.

Current automated coverage builds the menu bar app bundle and validates the source-level app contract for the menu, configurable press-and-hold voice-input hotkey, Quick Paste as the daily input mode, permission status display, on-device Apple Speech wiring, local context model rebuild, and local context model data controls. Manual macOS E2E should still verify microphone permission prompts, real speech transcription, Accessibility paste into another app, hotkey setting changes, permission status values, Quick Paste without preview or separate review UI, local context model learning, repository vocabulary, privacy expectations, and the export/import/delete menu actions.

`make check` also smoke-launches `.build/VoiceAgentInput.app` to catch immediate startup crashes. This does not replace the manual checklist because it does not interact with macOS permission prompts, menu items, microphone input, or target-app paste behavior.

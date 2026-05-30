# E2E tests

E2E coverage should exercise the real app or demo CLI path.

Current process-level coverage lives in `DemoCLITests` and runs the built `voice-agent-input-demo` executable for:

- preview mode,
- confirm mode,
- explicit no-submit behavior,
- candidate extraction from an edited prompt.

Future macOS E2E coverage should add the menu bar app, preview panel, hotkey, and pasteboard insertion once those targets exist.

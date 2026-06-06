# MVP completion audit

This audit tracks the evidence for the current MVP request. It intentionally distinguishes implemented and automatically verified behavior from behavior that still needs a real macOS desktop run.

## Current automated evidence

- `make check` runs Swift tests, fixture evals, app build, app bundle creation, app launch smoke, required-file validation, eval coverage validation, architecture boundary validation, app contract validation, privacy contract validation, MVP coverage validation, manual E2E artifact validation, and a smoke test for the manual privacy inspection helper.
- `make check` also smoke-runs the built `voice-agent-input-demo` command and verifies JSON normalization output for Claude Code, TypeScript, error, and local history-learning entries.
- Eval coverage validation requires realistic mixed Japanese-English developer terms such as Claude Code, Codex, Cursor, TypeScript, Swift, pnpm, npm, MCP, GitHub, branch, and error.
- Architecture boundary validation ensures Domain and App remain free of UI/macOS framework dependencies while framework-specific work stays in Infra.
- Component contract validation through required-file and MVP coverage checks ensures `VoiceInputPipeline`, `docs/contracts/`, and `docs/codex-sessions/` stay present.
- Privacy contract validation includes direct networking/cloud guards, an allowlist for Swift file writes, and debug-log raw transcript guards so raw transcript or raw audio persistence cannot be added silently.
- `DemoCLITests` exercise process-level normalization and history-learning flows.
- `UseCaseAndRepositoryTests` cover voice-flow orchestration, permission use cases, settings persistence, local context model persistence, repository vocabulary, STT recognition hints, and temporary audio cleanup.
- `PasteboardInsertionTests` cover pasteboard insertion, Accessibility paste insertion, and user-action enforcement; insertion requests expose no automatic-submit option.
- `EvalHarnessTests` covers fixture-driven normalization cases and history-derived context learning cases.

## Requirement evidence

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Invoke voice input from macOS | `AppKitKeyboardShortcutMonitor`, Control-Option-Space wiring, `Quick Paste Voice Input` menu item label, app launch smoke | Implemented, needs manual hotkey confirmation |
| Configure macOS permissions | `Permission Status...`, `Open Voice Input Permissions...`, permission provider use cases, app contract validation | Implemented, needs manual settings confirmation |
| Record microphone input | `AVFoundationAudioRecorder`, microphone permission use case, app contract validation | Implemented, needs real microphone confirmation |
| Transcribe speech | `AppleSpeechEngine`, on-device default, speech permission use case, app contract validation | Implemented, needs real speech confirmation |
| Normalize developer terms | domain normalization tests, fixture evals, eval coverage validation | Verified |
| Feed learned context into STT hints | `SpeechRecognitionHintsUseCase`, dictionary `recognitionHints`, Apple Speech contextual string tests | Verified |
| Reuse learned context after STT | history-learning eval fixtures, `AgentHistoryLearningModeUseCase`, `LocalContextModelBuildUseCase`, normalization tests | Verified |
| Quick Paste daily input compatibility | direct recording-flow insertion of `result.insertion`, app contract validation | Implemented, needs manual target-app confirmation |
| Prevent automatic submit | insertion request shape, insertion use case tests, pasteboard and Accessibility tests | Verified |
| Generate local context model entries for model education | source learning tests and entry extraction tests | Verified |
| Persist local context model data | local context model repository tests and rebuild tests | Verified |
| Export/import/open/delete local model data | local context model tests, `Model Education` submenu, `Open Local Data Folder...`, app contract validation | Implemented for local context model data, needs manual menu confirmation |
| Repository vocabulary as a learning source | git context tests, repository vocabulary tests, app contract validation | Implemented, needs manual folder selection confirmation |
| Local context model boundary | `LocalContextModel`, `LocalContextModelBuildUseCase`, `LocalContextModelRebuildUseCase`, `LocalContextModelDocumentCodec`, `JSONLocalContextModelRepository`, `DictionaryEntryLoadingUseCase`, `Model Education` submenu actions, `docs/contracts/local-context-model.md`, `docs/codex-sessions/local-context-model-session.md`, `SpeechRecognitionHintsUseCase`, learning source tests | Implemented with a versioned local JSON document including source kinds and last rebuild time; the app can rebuild the saved model without opening review/approval UI, hotkey runtime loads saved post-STT entries, and the app can export/import/delete the model |
| Local Foundation Model only if LLM is used | product docs, contracts, privacy validator network guards, and `PromptTextRefiner` keeping conversion outside STT and deterministic normalization | Verified for current source; adapter is local and explicit |
| Component-level future work boundaries | `docs/contracts/`, `docs/codex-sessions/`, `VoiceInputPipeline`, pipeline tests, MVP coverage validation | Verified structurally |
| Do not persist raw audio | AVFoundation temporary URL handoff, Apple Speech cleanup tests, `TemporaryRecordedAudioFileStore` fallback tests, no app-level recorded-audio debug hook, privacy contract validation | Verified for current adapters |
| Do not upload audio or transcripts | on-device Apple Speech default and privacy contract validation against direct networking/cloud snippets | Verified for current source |
| Do not persist raw transcripts by default | no transcript persistence adapter exists; debug logging records completed transcript length instead of raw text; raw speech snapshots stay inside the STT adapter and are not exposed to the app debug logger; privacy validation guards against raw speech snapshot logging callbacks; manual E2E privacy checklist covers Application Support inspection; `make manual-e2e-privacy-inspect` scans Application Support and the debug log after a real run | Verified for current source, needs manual filesystem confirmation |
| Do not auto-submit | insertion tests and manual E2E checklist | Verified at use-case/adapter level, needs target-app manual confirmation |

## Remaining completion evidence

The MVP should not be marked fully complete until a real macOS run fills out `test/e2e/manual-macos-mvp-report-template.md` with pass/fail evidence for:

- microphone permission prompt and recording,
- Apple Speech transcription,
- focused-cursor insertion or copy fallback through the current Quick Paste path,
- Control-Option-Space trigger in a desktop session,
- voice input permission shortcut,
- Accessibility paste into a focused target app,
- pasteboard fallback when Accessibility is not trusted,
- local context model export/import/open-folder/delete menu actions,
- repository folder selection and repository vocabulary learning source,
- Application Support privacy inspection for raw transcripts, including `make manual-e2e-privacy-inspect`,
- selected-repository privacy inspection for raw audio.

## Completion rule

Treat `make check` plus a completed passing manual macOS MVP report as the minimum evidence for declaring the MVP objective complete. If either is missing, the project can still be in a strong implemented state, but the full objective remains unproven.

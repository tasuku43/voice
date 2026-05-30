# MVP completion audit

This audit tracks the evidence for the current MVP request. It intentionally distinguishes implemented and automatically verified behavior from behavior that still needs a real macOS desktop run.

## Current automated evidence

- `make check` runs Swift tests, fixture evals, app build, app bundle creation, app launch smoke, required-file validation, eval coverage validation, architecture boundary validation, app contract validation, privacy contract validation, MVP coverage validation, and manual E2E artifact validation.
- `make check` also smoke-runs the built `voice-agent-input-demo` command and verifies JSON preview output for Claude Code, TypeScript, error, and explicit confirmation.
- Eval coverage validation requires realistic mixed Japanese-English developer terms such as Claude Code, Codex, Cursor, TypeScript, Swift, pnpm, npm, MCP, GitHub, branch, and error.
- Architecture boundary validation ensures Domain and App remain free of UI/macOS framework dependencies while framework-specific work stays in Infra.
- Component contract validation through required-file and MVP coverage checks ensures `PromptRefiner`, `VoiceInputPipeline`, `docs/contracts/`, and `docs/codex-sessions/` stay present.
- Privacy contract validation includes direct networking/cloud guards and an allowlist for Swift file writes so raw transcript or raw audio persistence cannot be added silently.
- `DemoCLITests` exercise process-level preview and confirm flows.
- `UseCaseAndRepositoryTests` cover voice-flow orchestration, permission use cases, settings persistence, candidate approval, local dictionary import/export/delete, repository vocabulary, and temporary audio cleanup.
- `PasteboardInsertionTests` cover pasteboard insertion, Accessibility paste insertion, explicit-confirmation enforcement, and automatic-submit rejection.
- `EvalHarnessTests` covers fixture-driven normalization cases.

## Requirement evidence

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Invoke voice input from macOS | `AppKitKeyboardShortcutMonitor`, Command-Shift-Space wiring, `Record Voice Input` menu item, app launch smoke | Implemented, needs manual hotkey confirmation |
| Configure macOS permissions | `Permission Status...`, `Open Privacy Settings...`, permission provider use cases, app contract validation | Implemented, needs manual settings confirmation |
| Record microphone input | `AVFoundationAudioRecorder`, microphone permission use case, app contract validation | Implemented, needs real microphone confirmation |
| Transcribe speech | `AppleSpeechEngine`, on-device default, speech permission use case, app contract validation | Implemented, needs real speech confirmation |
| Normalize developer terms | domain normalization tests, fixture evals, eval coverage validation | Verified |
| Show raw transcript and corrected prompt | `PromptPreviewUseCase`, preview window contract, use-case tests | Implemented, needs visual/manual confirmation |
| Allow edit before insertion | editable preview text view, prompt confirmation tests | Implemented, needs manual UI confirmation |
| Paste only after explicit confirmation | insertion use case tests, pasteboard and Accessibility tests | Verified |
| Extract dictionary candidates from edits | preview confirmation tests and candidate extractor tests | Verified |
| User approves or rejects candidates | app candidate approval dialog contract and candidate approval tests | Implemented, needs manual UI confirmation |
| Persist approved local dictionaries | JSON repository tests and local learning data tests | Verified |
| Export/import/open/delete local learning data | local learning data tests, `Open Local Data Folder...`, app contract validation | Implemented, needs manual menu confirmation |
| Repository-scoped vocabulary | git context tests, repository vocabulary tests, app contract validation | Implemented, needs manual folder selection confirmation |
| Component-level future work boundaries | `docs/contracts/`, `docs/codex-sessions/`, `PromptRefiner`, `VoiceInputPipeline`, pipeline tests, MVP coverage validation | Verified structurally |
| Do not persist raw audio | AVFoundation cleanup implementation, `TemporaryRecordedAudioFileStore` tests, privacy contract validation | Verified for current adapters |
| Do not upload audio or transcripts | on-device Apple Speech default and privacy contract validation against direct networking/cloud snippets | Verified for current source |
| Do not persist raw transcripts by default | no transcript persistence adapter exists; manual E2E privacy checklist covers Application Support inspection | Implemented by absence, needs manual filesystem confirmation |
| Do not auto-submit | insertion tests and manual E2E checklist | Verified at use-case/adapter level, needs target-app manual confirmation |

## Remaining completion evidence

The MVP should not be marked fully complete until a real macOS run fills out `test/e2e/manual-macos-mvp-report-template.md` with pass/fail evidence for:

- microphone permission prompt and recording,
- Apple Speech transcription,
- preview window rendering and editing,
- Command-Shift-Space trigger in a desktop session,
- Privacy & Security settings shortcut,
- Accessibility paste into a focused target app,
- pasteboard fallback when Accessibility is not trusted,
- candidate approval UI,
- local dictionary export/import/open-folder/delete menu actions,
- repository folder selection and repository vocabulary,
- Application Support privacy inspection for raw transcripts,
- selected-repository privacy inspection for raw audio.

## Completion rule

Treat `make check` plus a completed passing manual macOS MVP report as the minimum evidence for declaring the MVP objective complete. If either is missing, the project can still be in a strong implemented state, but the full objective remains unproven.

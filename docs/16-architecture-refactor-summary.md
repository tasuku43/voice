# Architecture refactor summary

This summarizes the component-boundary refactor whose goal is to make future Codex sessions work on one component with limited context.

## Current Dependency Shape

```text
VoiceAgentInputApp/main.swift
    -> VoiceAgentInputApp/VoiceAgentInputApp.swift
    -> App use cases and pipelines
        -> Domain algorithms and value types
    -> Infra adapters through protocols
```

Domain remains deterministic. App owns orchestration contracts and use cases. Infra owns framework, filesystem, git, and macOS adapters. The macOS shell owns menus, hotkey, dialogs, preview window, and paste-entry user actions. `main.swift` only starts `NSApplication` and installs `VoiceAgentInputApp` as the delegate. `PreviewWindowController` is isolated from the app delegate, and `CandidateApprovalDialogController` is isolated from the preview window, so focused AppKit work can stay inside one boundary at a time.

## Responsibility Moves

- Audio capture stays behind `AudioRecorder`; `AVFoundationAudioRecorder` is the macOS adapter.
- STT stays behind `SpeechToTextEngine`; `AppleSpeechEngine` is the on-device adapter.
- Dictionary and repository vocabulary loading moved toward `DictionaryContextLoadingUseCase`.
- Capture/STT orchestration is represented by `VoiceInputPipeline`.
- Post-STT text processing is represented by `PromptProcessingPipeline`.
- Dictionary replacement and refinement also expose `PromptTextTransform` for simple `String -> String` composition.
- Local context model aggregation is represented by `LocalContextModel` and `LocalContextModelBuildUseCase`.
- Future local Foundation Model fallback formatting is represented by `PromptRefiner`; the default is `NoOpPromptRefiner`.
- Candidate selection persistence moved toward `LearningApprovalUseCase`, leaving the UI to collect selected indexes.
- App startup is explicit in `main.swift`; menu and hotkey work lives in `VoiceAgentInputApp.swift`.
- Preview window rendering moved into `PreviewWindowController.swift`.
- Candidate approval dialog presentation moved out of `PreviewWindowController.swift` into `CandidateApprovalDialogController.swift`.
- Debug launch logging moved into `AppDebugLogger.swift`.
- Local dictionary import/export JSON encoding moved into `LocalLearningDataDocumentCodec`.
- Repository path and recording setting updates moved into `AppSettingsUseCase`.

## App Responsibilities Still Present

- Menu bar installation and menu commands.
- Hotkey start/stop.
- Debug launch diagnostics and optional local debug log.
- macOS permission status display and privacy-settings shortcut.
- Recording settings dialog.
- Preview window rendering and user edits in `PreviewWindowController.swift`.
- Candidate approval dialog presentation in `CandidateApprovalDialogController.swift`.
- Export/import/delete/open local learning menu actions.
- Error presentation.

These are acceptable UI boundary responsibilities. Further work can split menu command handlers into smaller AppKit types without changing Core contracts.

## Added Contracts

- `Transcript`
- `NormalizedPrompt`
- `RefinedPrompt`
- `PromptRefinementChange`
- `PromptNormalizer`
- `PromptRefiner`
- `PromptTextTransform`
- `LocalContextModel`
- `VoiceInputPipeline`
- `PromptProcessingPipeline`
- `DictionaryContextLoadingUseCase`
- `LearningApprovalUseCase`
- `LocalLearningDataDocumentCodec`
- `AppSettingsUseCase`

## Added Documentation

Component contracts:

- `docs/contracts/audio-capture.md`
- `docs/contracts/speech-to-text.md`
- `docs/contracts/local-context-model.md`
- `docs/contracts/normalization.md`
- `docs/contracts/prompt-refinement.md`
- `docs/contracts/voice-input-pipeline.md`
- `docs/contracts/preview-and-approval.md`
- `docs/contracts/learning.md`
- `docs/contracts/output.md`

Future Codex session prompts:

- `docs/codex-sessions/audio-capture-session.md`
- `docs/codex-sessions/speech-to-text-session.md`
- `docs/codex-sessions/local-context-model-session.md`
- `docs/codex-sessions/normalization-session.md`
- `docs/codex-sessions/prompt-refinement-session.md`
- `docs/codex-sessions/repository-vocabulary-session.md`
- `docs/codex-sessions/preview-ui-session.md`
- `docs/codex-sessions/learning-session.md`
- `docs/codex-sessions/output-session.md`

## Tests And Gates

- `make check` builds and smoke-launches the app bundle.
- Swift tests cover pipeline stage preservation, post-STT processing, text transform composition, learning approval, local data controls, permissions, insertion safety, and normalization evals.
- `validate_component_contracts.py` ensures contract and session docs keep the required short sections.
- `validate_architecture_refactor.py` checks the core refactor success criteria in one place: contracts, pipelines, text transforms, responsibility moves, and session prompts.
- `validate_architecture_boundaries.py` guards Domain and App use-case boundaries from macOS framework dependencies.
- `validate_app_ui_split.py` guards the menu-bar entrypoint from absorbing preview UI implementation again.
- `validate_privacy_contract.py` guards against direct network/cloud snippets and unexpected file writes.
- `validate_mvp_coverage.py` requires the new pipeline, transform, and session-boundary artifacts to stay present.

## Remaining Limitations

- `VoiceAgentInputApp/VoiceAgentInputApp.swift` is thinner but still contains most menu command code.
- `PreviewWindowController.swift` still contains insertion fallback UI.
- The prompt-refinement layer remains deterministic by default; local Foundation Model assistance can be integrated as opt-in model education or fallback conversion, not in the default STT or normalization hot path.
- Manual macOS E2E evidence is still required for microphone, Apple Speech, hotkey, Accessibility paste, candidate approval UI, local data menus, and privacy filesystem checks.

## Next Recommended Session

Prioritize `docs/codex-sessions/local-context-model-session.md` if the goal is to align implementation with the product direction. Make learned context explicit, rebuildable, and usable for both STT recognition hints and post-STT transforms.

Prioritize `docs/codex-sessions/preview-ui-session.md` if the goal is to make the AppKit shell thinner. Split menu command handlers or insertion fallback presentation into AppKit boundary types while keeping learning and insertion in Core use cases.

Prioritize `docs/codex-sessions/prompt-refinement-session.md` if the goal is to add real local prompt cleanup. Keep the default no-op path and preserve the `PromptTextTransform` shape.

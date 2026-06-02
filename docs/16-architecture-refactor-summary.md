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

Domain remains deterministic. App owns orchestration contracts and use cases. Infra owns framework, filesystem, git, and macOS adapters. The macOS shell owns menus, hotkey, dialogs, recording HUD, and paste-entry user actions. `main.swift` only starts `NSApplication` and installs `VoiceAgentInputApp` as the delegate.

## Responsibility Moves

- Audio capture stays behind `AudioRecorder`; `AVFoundationAudioRecorder` is the macOS adapter.
- STT stays behind `SpeechToTextEngine`; `AppleSpeechEngine` is the on-device adapter.
- Dictionary and repository vocabulary loading moved toward `DictionaryContextLoadingUseCase`.
- Capture/STT orchestration is represented by `VoiceInputPipeline`.
- Post-STT text processing is represented by `PromptProcessingPipeline`.
- Dictionary replacement exposes `PromptNormalizer.normalizeText` for simple `String -> String` checks.
- Local context model aggregation is represented by `LocalContextModel` and `LocalContextModelBuildUseCase`; local persistence is behind `LocalContextModelRepository` with `JSONLocalContextModelRepository` as the filesystem adapter.
- Future Foundation Model conversion must live behind an explicit local-only fallback boundary, not the default hotkey processing path.
- Local context model rebuilds moved into `LocalContextModelDataUseCase`, leaving the UI to choose sources and trigger rebuilds.
- App startup is explicit in `main.swift`; menu and hotkey work lives in `VoiceAgentInputApp.swift`.
- Debug launch logging moved into `AppDebugLogger.swift`.
- Local app data storage is represented by `LocalAppDataStore`, which creates settings and local context model repositories.
- Repository path and recording setting updates moved into `AppSettingsUseCase`.

## App Responsibilities Still Present

- Menu bar installation and menu commands.
- Hotkey start/stop.
- Optional local debug log.
- macOS permission status display and privacy-settings shortcut.
- Hotkey settings dialog.
- Export/import/delete/open local learning menu actions.
- Error presentation.

These are acceptable UI boundary responsibilities. Further work can split menu command handlers into smaller AppKit types without changing Core contracts.

## Added Contracts

- `Transcript`
- `NormalizedPrompt`
- `PromptNormalizer`
- `LocalContextModel`
- `LocalContextModelDocumentCodec`
- `LocalContextModelRepository`
- `VoiceInputPipeline`
- `PromptProcessingPipeline`
- `DictionaryContextLoadingUseCase`
- `LocalAppDataStore`
- `AppSettingsUseCase`

## Added Documentation

Component contracts:

- `docs/contracts/audio-capture.md`
- `docs/contracts/speech-to-text.md`
- `docs/contracts/local-context-model.md`
- `docs/contracts/normalization.md`
- `docs/contracts/voice-input-pipeline.md`
- `docs/contracts/learning.md`
- `docs/contracts/output.md`

Future Codex session prompts:

- `docs/codex-sessions/audio-capture-session.md`
- `docs/codex-sessions/speech-to-text-session.md`
- `docs/codex-sessions/local-context-model-session.md`
- `docs/codex-sessions/normalization-session.md`
- `docs/codex-sessions/repository-vocabulary-session.md`
- `docs/codex-sessions/learning-session.md`
- `docs/codex-sessions/output-session.md`

## Tests And Gates

- `make check` builds and smoke-launches the app bundle.
- Swift tests cover pipeline stage preservation, post-STT processing, local context model learning, local data controls, permissions, insertion safety, and normalization evals.
- `validate_component_contracts.py` ensures contract and session docs keep the required short sections.
- `validate_architecture_refactor.py` checks the core refactor success criteria in one place: contracts, pipelines, responsibility moves, and session prompts.
- `validate_architecture_boundaries.py` guards Domain and App use-case boundaries from macOS framework dependencies.
- `validate_app_ui_split.py` guards against reintroducing preview/edit UI or candidate approval UI into the app source.
- `validate_privacy_contract.py` guards against direct network/cloud snippets and unexpected file writes.
- `validate_mvp_coverage.py` requires the new pipeline and session-boundary artifacts to stay present.

## Remaining Limitations

- `VoiceAgentInputApp/VoiceAgentInputApp.swift` is thinner but still contains most menu command code.
- Local Foundation Model assistance can be integrated as opt-in model education or fallback conversion, not in the default STT or normalization hot path.
- Manual macOS E2E evidence is still required for microphone, Apple Speech, hotkey, Accessibility paste, local data menus, and privacy filesystem checks.

## Next Recommended Session

Prioritize `docs/codex-sessions/local-context-model-session.md` when improving model education. Preserve the default dictionary-only hotkey path.

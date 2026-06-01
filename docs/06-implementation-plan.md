# Implementation plan

## Phase 1: core engine

- Dictionary model.
- Local context model shape.
- Scope precedence.
- Normalization pipeline.
- Recognition hint generation.
- Candidate extraction.
- JSON persistence.
- Unit tests and evals.

## Phase 2: macOS shell

- Menu bar app. Minimal mock shell done.
- Floating preview panel. Minimal editable mock preview done.
- Apple Speech integration. Initial bundled app flow records audio and transcribes through on-device `AppleSpeechEngine`.
- Recording state. App shell disables repeat recording triggers while a recording/transcription flow is already running.
- Recording settings. App shell can set local recording duration and Speech locale for later recordings.
- Permission status. App shell can display current microphone, speech recognition, and Accessibility paste permission states.
- Focused cursor insertion or copy fallback.
- Optional confirm-before-paste preview flow.

## Phase 3: input loop

- Global hotkey. Initial AppKit global/local monitor done for Control-Option-Space.
- Pasteboard insertion. Done for text-only adapter and wired into the app shell.
- Accessibility paste insertion. Initial adapter sends Command-V for the user-invoked voice input action; copy fallback is used if Accessibility access is not granted.
- Explicit no-submit behavior.

## Phase 4: real audio and STT

- Audio recorder abstraction. Done as protocol plus mock recorder.
- AVFoundation microphone recorder. Initial adapter done; it uses a temporary local file and deletes it after reading audio data.
- Apple Speech adapter. Initial `SFSpeechRecognizer` file transcription adapter and permission provider wired into bundled app flow.
- Availability guards.
- Mock engine retained for tests.

## Phase 5: model education loop

- Learning source selection. Initial app flow done.
- Local Codex / Claude Code history source. Done through bounded local history adapters.
- Git repository vocabulary source. Done through explicit repository vocabulary learning source.
- Local context model rebuild. The app can rebuild and persist the local context model from selected sources without entering candidate approval.
- Optional editable prompt preview.
- Optional diff extraction.
- Optional candidate approval UI. App-shell approval dialog supports per-candidate selection.
- Local dictionary persistence. JSON-backed Application Support store done.
- Local learning data controls. App-shell menu can export, import, inspect, and delete approved local dictionary entries.

## Phase 6: repository context

- Git root and branch detection. Initial command-backed provider done.
- Bounded vocabulary extraction. Tracked file names from `git ls-files` are filtered by extension and capped before becoming repository-scoped entries.
- Repository-scoped suggestions. Repository name, branch, and tracked file-name entries are available through explicit learning-source selection and model rebuilds.
- Manual repository folder setting. App shell can store a local repository path for bundled/Finder launches.

## Phase 7: local Foundation Model fallback

- Local Foundation Model adapter protocol.
- Model education assistance only after explicit enablement.
- Optional last-resort conversion stage outside the default hotkey path.
- No network IO, no cloud STT, and no transcript upload.

# Spec trim audit

This document is the current product-shaping checkpoint. `AGENTS.md` captured an early preview-and-approval-heavy MVP, but the product center is now narrower:

```text
hotkey voice input
  -> local STT
  -> built-in developer vocabulary
  -> local context model
  -> optional local Foundation Model fallback
  -> focused cursor insertion
```

The app must run fully locally. Network IO is out of scope for STT, model education, and any LLM-style fallback. If an LLM is introduced, it means a local Foundation Model adapter.

## Keep

- Configurable macOS hotkey invocation.
- Press-and-hold and toggle recording.
- Local microphone capture and local/on-device STT adapters.
- Built-in developer vocabulary transforms.
- A rebuildable local context model made from bounded local sources.
- Learning-source adapters for Codex / Claude local sessions and Git repository vocabulary.
- Future explicit adapters for GitHub, Slack, Chatwork, and similar context sources.
- Recognition hints before STT when the adapter supports them.
- Deterministic post-STT transforms after transcription.
- Focused cursor insertion with copy fallback.
- Local storage, export, import, and deletion for learned context.
- Optional local Foundation Model use for model education, and only as an explicit last-resort conversion fallback in the voice input path.

## Demote

- Preview/edit UI is an optional curation surface, not the primary experience.
- Candidate approve/reject UI is useful for manual curation, but it must not be required for the default voice input path.
- Generic learning reviewer commands are removed; detectors and future local Foundation Model reviewers belong off the hotkey STT path.
- Repository folders configure learning sources; they should not silently broaden the runtime dictionary without an explicit model rebuild.

## Drop

- Any requirement that the default hotkey path show a preview before insertion.
- Any requirement that normal dictation wait for candidate approval.
- Any cloud STT, cloud LLM, transcript upload, cloud sync, or team dictionary sharing in the MVP.
- Automatic prompt submission after insertion.
- Full IME behavior or character-by-character live insertion.

## Current Evidence

- `VoiceAgentInputApp.recordVoiceInput()` uses Quick Paste as the daily path and keeps Learning Preview optional.
- `AgentHistoryLearningModeUseCase` reads bounded local learning sources and generates candidates without network IO.
- `LocalContextModelDataUseCase.rebuildModel(...)` persists a local model document from learning results.
- `Local Context Model Status...` shows the saved model's last rebuild time, source kinds, source text counts, generated candidates, runtime entry count, and stale-source warnings without rebuilding.
- `DictionaryEntryLoadingUseCase` loads saved `LocalContextModel.postSTTEntries` into the hotkey runtime.
- `SpeechRecognitionHintsUseCase` turns runtime dictionary entries into STT contextual strings.
- Privacy validators reject direct networking/cloud snippets in the current Swift app sources.

## Remaining Shape Work

- Local context model status/rebuild/export/import/delete UI is implemented, and the model stores source kinds plus last rebuild time; add source freshness checks based on content modification times after the last rebuild.
- Decide which optional curation surfaces stay visible by default after the model education flow is stronger.
- Add local Foundation Model protocols only after deterministic model education and runtime transforms are not enough.

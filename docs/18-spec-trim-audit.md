# Spec trim audit

This document is the current product-shaping checkpoint. `AGENTS.md` captured an early preview-heavy MVP, but the product center is now narrower:

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
- Press-and-hold recording.
- Local microphone capture and local/on-device STT adapters.
- Built-in developer vocabulary transforms.
- A rebuildable local context model made from bounded local sources.
- Learning-source adapters for Codex / Claude local sessions and Git repository vocabulary.
- Future explicit local archive/cache adapters for GitHub, Slack, Chatwork, and similar context sources.
- Recognition hints before STT when the adapter supports them.
- Deterministic post-STT transforms after transcription.
- Focused cursor insertion with copy fallback.
- Local storage, export, import, and deletion for learned context.
- Optional local Foundation Model use for model education, and only as an explicit last-resort conversion fallback in the voice input path.

## Demote

- Preview/edit UI has been removed from the current app; Accessibility failures use pasteboard copy fallback.
- Generic learning reviewer commands are removed; detectors and future local Foundation Model helpers belong in the model education path, not the hotkey STT path.
- Repository folders configure learning sources; they should not silently broaden the runtime dictionary without an explicit model rebuild.

## Drop

- Any requirement that the default hotkey path show a preview before insertion.
- Any requirement that normal dictation wait for candidate approval.
- Candidate approve/reject UI for the current MVP.
- Edit-derived learning from preview confirmation.
- Any cloud STT, cloud LLM, transcript upload, cloud sync, or team dictionary sharing in the MVP.
- Automatic prompt submission after insertion.
- Full IME behavior or character-by-character live insertion.

## Current Evidence

- `VoiceAgentInputApp.recordVoiceInput()` uses Quick Paste as the only normal voice input path.
- `AgentHistoryLearningModeUseCase` reads bounded local learning sources and generates candidates without network IO.
- `LocalContextModelRebuildUseCase.rebuild(...)` runs selected learning sources and persists a local model document from learning results.
- `Local Context Model Status...` shows the saved model's last rebuild time, source kinds, source text counts, generated candidates, runtime entry count, and stale-source warnings without rebuilding.
- `DictionaryEntryLoadingUseCase` loads saved `LocalContextModel.postSTTEntries` into the hotkey runtime.
- `SpeechRecognitionHintsUseCase` turns runtime dictionary entries into STT contextual strings.
- Privacy validators reject direct networking/cloud snippets in the current Swift app sources.

## Remaining Shape Work

- Local context model status/rebuild/export/import/delete UI is implemented, and the model stores source kinds plus last rebuild time; add source freshness checks based on content modification times after the last rebuild.
- Add local Foundation Model protocols only after deterministic model education and runtime transforms are not enough.

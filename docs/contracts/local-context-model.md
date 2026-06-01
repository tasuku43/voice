# Local Context Model Contract

## Inputs
- Built-in developer vocabulary.
- Approved user dictionary entries.
- Bounded local Codex / Claude Code session text.
- Bounded Git repository vocabulary.
- Future bounded local GitHub, Slack, Chatwork, or similar adapter output.
- Optional local Foundation Model education output.

## Outputs
- Recognition hints for STT adapters.
- Post-STT transform entries.
- Source metadata that explains where context came from.
- Confidence and scope metadata.

The local context model is not an LLM. In the MVP it is structured local data: canonical terms, spoken forms, ASR-friendly recognition hints, source counts, scopes, and deterministic transform metadata.

The current implementation starts with `LocalContextModel` and `LocalContextModelBuildUseCase`, which combine seed entries, approved entries, and optionally generated learning candidates into one in-memory model. A separate persistence document shape is still future work.

## Allowed
- Merge built-in vocabulary and local learned context.
- Produce bounded `SpeechRecognitionHints` before STT.
- Produce deterministic dictionary entries for post-STT correction.
- Preserve enough source metadata for local inspection and rebuilds.
- Use a local Foundation Model during model education when explicitly enabled.
- Use local Foundation Model output only if no network IO occurs.
- Rebuild from enabled local sources.
- Export, import, and delete local context data.

## Forbidden
- Audio capture.
- Speech recognition itself.
- UI rendering.
- Paste, automatic submit, or command execution.
- Network IO.
- Cloud STT or cloud LLM calls.
- Persisting raw audio.
- Persisting raw transcripts by default.
- Unbounded repository or chat history scans.

## Read First
- `src/VoiceAgentInputCore/Domain/DictionaryEntry.swift`
- `src/VoiceAgentInputCore/App/LocalContextModel.swift`
- `src/VoiceAgentInputCore/App/SpeechRecognitionHints.swift`
- `src/VoiceAgentInputCore/App/DictionaryEntryLoadingUseCase.swift`
- `src/VoiceAgentInputCore/App/LearningSource.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift`
- `src/VoiceAgentInputCore/App/RepositoryVocabularyLearningSource.swift`
- `docs/contracts/learning.md`
- `docs/contracts/speech-to-text.md`
- `docs/contracts/normalization.md`

## May Touch
- Local context model value types.
- Recognition hint generation.
- Learning-source aggregation.
- Local persistence codecs for learned context.
- Fixture-driven context model evals.

## Avoid Touching
- AppKit UI.
- Audio recorder internals.
- Text insertion adapters.
- Candidate approval UI, unless it is being explicitly kept as an optional curation surface.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testSpeechRecognitionHintsUseDictionaryEntriesForContextualStrings`
- `swift test --filter UseCaseAndRepositoryTests/testLearningModeCanCombineAgentHistoryAndRepositoryVocabularySources`
- Future: context-model fixture evals for each learning-source adapter.
- `make check`

## Done
- The model can feed both STT recognition hints and post-STT transforms.
- Source adapters remain bounded and local.
- Local Foundation Model use, if present, is optional and network-free.
- The default hotkey path can run without LLM conversion.

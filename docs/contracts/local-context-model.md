# Local Context Model Contract

## Inputs
- Built-in developer vocabulary.
- Bounded local Codex / Claude Code session text.
- Bounded Git repository vocabulary.
- Future bounded local archive/cache output for GitHub, Slack, Chatwork, or similar tools.
- Optional local Foundation Model education output.

## Outputs
- Recognition hints for STT adapters.
- Post-STT transform entries.
- Source metadata that explains where context came from.
- Confidence and scope metadata.

The local context model is not an LLM. In the MVP it is structured local data: canonical terms, spoken forms, ASR-friendly recognition hints, source counts, source kinds, last rebuild metadata, scopes, and deterministic transform metadata.

The current implementation starts with `LocalContextModel` and `LocalContextModelBuildUseCase`, which combine seed entries and optionally generated learning candidates into one model. `LocalContextModelDataUseCase.rebuildModel(...)` saves that model after learning-source runs. `LocalContextModelDocumentCodec` stores the model in a versioned JSON document, `JSONLocalContextModelRepository` is the local filesystem adapter, and `DictionaryEntryLoadingUseCase` loads saved `postSTTEntries` into the hotkey runtime.

## Allowed
- Merge built-in vocabulary and local learned context.
- Produce bounded `SpeechRecognitionHints` before STT.
- Produce deterministic dictionary entries for post-STT correction.
- Preserve enough source metadata for local inspection and rebuilds.
- Use a local Foundation Model during model education when explicitly enabled.
- Accept output only from local Foundation Model adapters; network IO remains forbidden.
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
- `src/VoiceAgentInputCore/App/LocalContextModelDocumentCodec.swift`
- `src/VoiceAgentInputCore/App/LocalContextModelRepository.swift`
- `src/VoiceAgentInputCore/App/SpeechRecognitionHints.swift`
- `src/VoiceAgentInputCore/App/DictionaryEntryLoadingUseCase.swift`
- `src/VoiceAgentInputCore/App/LearningSource.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift`
- `src/VoiceAgentInputCore/App/RepositoryVocabularyLearningSource.swift`
- `src/VoiceAgentInputCore/Infra/JSONLocalContextModelRepository.swift`
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
- Preview or candidate approval UI.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testSpeechRecognitionHintsUseDictionaryEntriesForContextualStrings`
- `swift test --filter UseCaseAndRepositoryTests/testLearningModeCanCombineAgentHistoryAndRepositoryVocabularySources`
- `swift test --filter UseCaseAndRepositoryTests/testLocalContextModelDocumentCodecRoundTrip`
- `swift test --filter UseCaseAndRepositoryTests/testJSONLocalContextModelRepositoryRoundTripAndDelete`
- Future: context-model fixture evals for each learning-source adapter.
- `make check`

## Done
- The model can feed both STT recognition hints and post-STT transforms.
- The model has a versioned local JSON document shape.
- Source adapters remain bounded and local.
- Local Foundation Model use, if present, is optional, local, and network-free.
- The default hotkey path can run without LLM conversion.

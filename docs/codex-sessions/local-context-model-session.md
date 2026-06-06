Purpose: define and implement the local context model that powers environment-adaptive voice input.

Read:
- `docs/contracts/local-context-model.md`
- `docs/contracts/learning.md`
- `docs/contracts/speech-to-text.md`
- `docs/contracts/normalization.md`
- `docs/14-architecture.md`
- `src/VoiceAgentInputCore/Domain/DictionaryEntry.swift`
- `src/VoiceAgentInputCore/App/SpeechRecognitionHints.swift`
- `src/VoiceAgentInputCore/App/LearningSource.swift`

May touch:
- Domain value types for local context model entries.
- App use cases that aggregate dictionaries and learning sources.
- Local persistence codecs.
- Fixture-driven evals for recognition hints and post-STT transforms.

Avoid:
- AppKit UI work.
- Audio recorder internals.
- Text insertion adapters.
- Network-backed integrations.

Contract:
- `docs/contracts/local-context-model.md`

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testSpeechRecognitionHintsUseDictionaryEntriesForContextualStrings`
- `swift test --filter UseCaseAndRepositoryTests/testLearningModeCanCombineAgentHistoryAndRepositoryVocabularySources`
- Add fixture-driven context model evals when a concrete model document shape is introduced.
- `make check`

Done:
- Local context model data is explicit, persisted locally, and rebuildable.
- The same model can produce STT recognition hints and deterministic post-STT transforms.
- Any local Foundation Model use is optional, network-free, and either model education or explicit post-STT refinement.

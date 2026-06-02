# Learning Contract

## Inputs
- Bounded local Codex/Claude history text for explicit learning mode.
- Configured repository vocabulary exposed through a learning-source adapter.
- Future bounded local archive/cache text from GitHub, Slack, Chatwork, or similar tools.

## Outputs
- `CorrectionCandidate`
- Candidate reason.
- Local context model entries for recognition hints and post-STT transforms.

## Allowed
- Generate local context candidates from local learning sources after explicit user action.
- Let the user choose local learning sources before rebuilding the local context model.
- Report source-level scan counts so the app can explain what was used.
- Build local context model data from bounded source adapters.
- Use local Foundation Model assistance for model education when explicitly enabled and local-only.
- Keep Quick Paste outside candidate review and approval; the recording flow inserts the corrected prompt with no learning candidates.
- Skip agent-history candidates already represented in loaded dictionaries.
- Reuse deterministic developer-term speech rules across source learning.
- Treat repository folders as learning-source configuration, not automatic hotkey runtime context.
- Build local context model entries without candidate approval UI.
- Keep voice-input edits out of model education.
- Keep model education separate from the ordinary voice-input app layer.

## Forbidden
- Speech recognition.
- Prompt refinement.
- Automatic context model updates from voice-input edits.
- Paste or automatic submit.
- Network IO.
- Cloud model calls.

## Read First
- `src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryTextProvider.swift`
- `src/VoiceAgentInputCore/App/LearningSource.swift`
- `src/VoiceAgentInputCore/App/LearningSourceSelection.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift`
- `src/VoiceAgentInputCore/App/LocalContextCandidateGenerationUseCase.swift`
- `src/VoiceAgentInputCore/App/RepositoryVocabularyLearningSource.swift`
- `src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift`

## May Touch
- Source learning, candidate generation, and learning persistence tests.

## Avoid Touching
- Audio, speech, and output adapters.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testLocalContextCandidateGenerationFindsRepeatedDeveloperTerms`
- `swift test --filter UseCaseAndRepositoryTests/testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms`
- `make check`

## Done
- Voice-input edits do not generate model education candidates.
- Agent history reads stay behind an app-level provider and infra adapter.
- Learning-source adapters remain bounded and local.
- Learned context can feed both STT recognition hints and deterministic post-STT transforms.
- Quick Paste remains a fast rule-based insertion path with no learning reviewer or candidate approval dialog.
- Repository vocabulary is available as an explicit learning source and is not mixed into the runtime dictionary by default.

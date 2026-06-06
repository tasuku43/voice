# Learning Session

Purpose: improve local model education from bounded learning sources.

Read:
- `docs/contracts/learning.md`
- `src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryTextProvider.swift`
- `src/VoiceAgentInputCore/App/LearningSource.swift`
- `src/VoiceAgentInputCore/App/LearningSourceSelection.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift`
- `src/VoiceAgentInputCore/App/LocalContextCandidateGenerationUseCase.swift`
- `src/VoiceAgentInputCore/App/LocalContextModel.swift`
- `src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift`

May touch:
- Source learning, candidate generation, and local context model tests.

Avoid:
- Speech engines and output adapters.

Contract:
- Candidates include a reason.
- Local agent history learning is explicit, bounded, and local-only.
- Repository vocabulary learning is explicit, bounded, and local-only.
- Local context model rebuilds can feed both recognition hints and post-STT transforms.
- Voice-input edits do not create learning entries.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testLocalContextCandidateGenerationFindsRepeatedDeveloperTerms`
- `swift test --filter UseCaseAndRepositoryTests/testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms`
- `make check`

Done:
- Candidates are explainable and model rebuilds stay outside the hotkey voice-input path.

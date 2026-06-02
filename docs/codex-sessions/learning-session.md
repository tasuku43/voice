# Learning Session

Purpose: improve local model education from bounded learning sources.

Read:
- `docs/contracts/learning.md`
- `src/VoiceAgentInputCore/Domain/CandidateExtractor.swift`
- `src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift`
- `src/VoiceAgentInputCore/Domain/VoiceMisrecognitionDetector.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryTextProvider.swift`
- `src/VoiceAgentInputCore/App/LearningSource.swift`
- `src/VoiceAgentInputCore/App/LearningSourceSelection.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift`
- `src/VoiceAgentInputCore/App/LocalContextCandidateGenerationUseCase.swift`
- `src/VoiceAgentInputCore/App/LocalContextModel.swift`
- `src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift`

May touch:
- Candidate extraction, source learning, and local context model tests.

Avoid:
- Speech engines, prompt refinement, output adapters.

Contract:
- Candidates include a reason.
- Likely voice misrecognition detection is replaceable, so an LLM adapter can be used outside the hot path later.
- Local agent history learning is explicit, bounded, and local-only.
- Repository vocabulary learning is explicit, bounded, and local-only.
- Local context model rebuilds can feed both recognition hints and post-STT transforms.
- Dangerous substitutions are not auto-applied.

Tests:
- `swift test --filter CandidateExtractorTests`
- `swift test --filter UseCaseAndRepositoryTests/testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms`
- `make check`

Done:
- Candidates are explainable and model rebuilds stay outside the hotkey voice-input path.

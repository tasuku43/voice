# Learning Session

Purpose: improve candidate extraction and approval flow from user edits.

Read:
- `docs/contracts/learning.md`
- `src/VoiceAgentInputCore/Domain/CandidateExtractor.swift`
- `src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift`
- `src/VoiceAgentInputCore/Domain/VoiceMisrecognitionDetector.swift`
- `src/VoiceAgentInputCore/App/PromptEditLearningUseCase.swift`
- `src/VoiceAgentInputCore/App/DictionaryLearningUseCase.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryTextProvider.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryDictionaryLearningUseCase.swift`
- `src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift`
- `src/VoiceAgentInputCore/Infra/LocalCommandLearningCandidateReviewer.swift`
- `docs/contracts/learning-reviewer-command.md`
- `scripts/local_learning_reviewer_example.py`

May touch:
- Candidate extraction, approval, and local learning tests.

Avoid:
- Speech engines, prompt refinement, output adapters.

Contract:
- User approval is required.
- Candidates include a reason.
- Likely voice misrecognition detection is replaceable, so an LLM adapter can be used outside the hot path later.
- Edit-derived candidates can be reviewed after preview confirmation without touching the transcription or normalization path.
- Local command-based candidate review is opt-in through settings and preserves dangerous substitution guardrails.
- Local agent history learning is explicit, bounded, and local-only.
- Dangerous substitutions are not auto-applied.

Tests:
- `swift test --filter CandidateExtractorTests`
- `swift test --filter UseCaseAndRepositoryTests/testApprovedCandidatesPersistAsLocalDictionaryEntries`
- `make check`

Done:
- Candidates are explainable and persistence is approval-gated.

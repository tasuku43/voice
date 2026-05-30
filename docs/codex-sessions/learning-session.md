# Learning Session

Purpose: improve candidate extraction and approval flow from user edits.

Read:
- `docs/contracts/learning.md`
- `src/VoiceAgentInputCore/Domain/CandidateExtractor.swift`
- `src/VoiceAgentInputCore/App/DictionaryLearningUseCase.swift`

May touch:
- Candidate extraction, approval, and local learning tests.

Avoid:
- Speech engines, prompt refinement, output adapters.

Contract:
- User approval is required.
- Candidates include a reason.
- Dangerous substitutions are not auto-applied.

Tests:
- `swift test --filter CandidateExtractorTests`
- `swift test --filter UseCaseAndRepositoryTests/testApprovedCandidatesPersistAsLocalDictionaryEntries`
- `make check`

Done:
- Candidates are explainable and persistence is approval-gated.

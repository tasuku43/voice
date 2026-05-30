# Learning Contract

## Inputs
- Raw transcript.
- Corrected or refined prompt.
- User final edited text.

## Outputs
- `CorrectionCandidate`
- Candidate reason.
- Approval or rejection state.

## Allowed
- Generate dictionary candidates from user edits.
- Persist approved entries only after user approval.

## Forbidden
- Speech recognition.
- Prompt refinement.
- Automatic dangerous dictionary updates.
- Paste or automatic submit.

## Read First
- `src/VoiceAgentInputCore/Domain/CandidateExtractor.swift`
- `src/VoiceAgentInputCore/App/DictionaryLearningUseCase.swift`
- `src/VoiceAgentInputCore/App/CandidateApprovalUseCase.swift`

## May Touch
- Candidate extraction and learning persistence tests.

## Avoid Touching
- Audio, speech, and output adapters.

## Tests
- `swift test --filter CandidateExtractorTests`
- `swift test --filter UseCaseAndRepositoryTests/testApprovedCandidatesPersistAsLocalDictionaryEntries`
- `make check`

## Done
- Rejected and dangerous candidates are not auto-applied.
- Approved entries are stored locally.

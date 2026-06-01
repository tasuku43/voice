# Learning Contract

## Inputs
- Raw transcript.
- Corrected or refined prompt.
- User final edited text.
- Bounded local Codex/Claude history text for explicit learning mode.
- Configured repository vocabulary exposed through a learning-source adapter.
- Future bounded local source text from GitHub, Slack, Chatwork, or similar adapters.

## Outputs
- `CorrectionCandidate`
- Candidate reason.
- Approval or rejection state.
- Local context model entries for recognition hints and post-STT transforms.

## Allowed
- Generate dictionary candidates from user edits.
- Generate dictionary candidates from local learning sources after explicit user action.
- Let the user choose local learning sources before training the dictionary.
- Report source-level scan counts so the app can explain what was used.
- Build local context model data from bounded source adapters.
- Use local Foundation Model assistance for model education when explicitly enabled and local-only.
- Keep Quick Paste outside candidate review and approval; the recording flow inserts the corrected prompt with no learning candidates.
- Skip agent-history candidates already represented in loaded dictionaries.
- Reuse deterministic developer-term speech rules across history learning and edit learning.
- Treat repository folders as learning-source configuration, not automatic hotkey runtime context.
- Use user scope by default for edit-derived candidates when optional preview fallback is used.
- Score likely voice misrecognitions behind a replaceable detector.
- Review edit-derived candidates after preview confirmation through an off-transcription-path detector or future local Foundation Model adapter, without slowing STT or deterministic prompt normalization.
- If candidate review fails, confirmation still returns the prompt and unreviewed candidates; optional review must not block paste confirmation.
- Persist approved entries only after user approval.
- Re-approving an equivalent candidate strengthens the existing entry instead of duplicating it.

## Forbidden
- Speech recognition.
- Prompt refinement.
- Automatic dangerous dictionary updates.
- Paste or automatic submit.
- Network IO.
- Cloud model calls.

## Read First
- `src/VoiceAgentInputCore/Domain/CandidateExtractor.swift`
- `src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift`
- `src/VoiceAgentInputCore/Domain/VoiceMisrecognitionDetector.swift`
- `src/VoiceAgentInputCore/App/PromptEditLearningUseCase.swift`
- `src/VoiceAgentInputCore/App/DictionaryLearningUseCase.swift`
- `src/VoiceAgentInputCore/App/CandidateApprovalUseCase.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryTextProvider.swift`
- `src/VoiceAgentInputCore/App/LearningSource.swift`
- `src/VoiceAgentInputCore/App/LearningSourceSelection.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift`
- `src/VoiceAgentInputCore/App/AgentHistoryDictionaryLearningUseCase.swift`
- `src/VoiceAgentInputCore/App/RepositoryVocabularyLearningSource.swift`
- `src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift`

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
- Agent history reads stay behind an app-level provider and infra adapter.
- Learning-source adapters remain bounded and local.
- Learned context can feed both STT recognition hints and deterministic post-STT transforms.
- Candidate review remains off the default hotkey path and preserves dangerous substitution guardrails.
- Quick Paste remains a fast rule-based insertion path with no learning reviewer or candidate approval dialog.
- Optional preview fallback edit learning uses the configured preferred learning scope.
- Repository vocabulary is available as an explicit learning source and is not mixed into the runtime dictionary by default.

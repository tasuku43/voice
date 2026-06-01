# Learning Goal Audit

This audit maps the current implementation to the product goal of a fully local, mostly rule-based voice input tool that can educate a local context model from environment-specific vocabulary. LLM-style assistance must be local Foundation Model usage only, primarily for model education, and optional as a last-resort conversion stage outside the default hotkey path.

## Requirements And Evidence

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Keep ordinary hotkey dictation mostly rule-based and fast. | `VoiceInputPipeline` records and transcribes, then `PromptProcessingPipeline` runs `DictionaryPromptNormalizer` and `JapanesePunctuationPromptRefiner`. In default `Quick Paste` mode the app inserts `result.preview.correctedPrompt` directly with no learning reviewer and no candidate approval dialog; `Learning Preview` remains an optional curation surface. | Implemented |
| Treat dictionary replacement and prompt refinement as text-to-text layers. | `PromptTextTransform`, `DictionaryPromptTextTransform`, `RefinementPromptTextTransform`, and tests `testPromptTransformsExposeTextToTextConvenience` and `testPromptTextTransformPipelineComposesDictionaryAndRefinementLayers`. | Implemented |
| Reuse learned context before and after ASR. | `DictionaryEntry` stores `recognitionHints` for ASR-first vocabulary biasing and `spokenForms` for post-STT correction. `LocalContextModel` wraps entries and exposes both `recognitionHints` and `postSTTEntries`. `LocalContextModelDocumentCodec` and `JSONLocalContextModelRepository` provide a versioned local JSON document for the model. `SpeechRecognitionHintsUseCase` converts loaded `recognitionHints` into bounded `contextualStrings`; `VoiceAgentInputApp.recordVoiceInput()` passes those hints into `AppleSpeechEngine`, while the same entries still feed `NormalizationContext` for fallback correction. Tests cover recognition-hint preference, legacy dictionary decoding, dictionary-to-hint conversion, local context model outputs, local model persistence, and Apple Speech request wiring. | Implemented |
| Educate a local context model from environment-specific sources. | `LearningSource`, `LearningSourceSelection`, `LocalAgentHistoryTextProvider`, `RepositoryVocabularyLearningSource`, `AgentHistoryLearningModeUseCase`, `AgentHistoryDictionaryLearningUseCase`, menu items `Train Dictionary From Sources...` and `Learn From Agent History...`, and tests for bounded local history loading, structured user text extraction, source text counts, candidate generation, duplicate skipping, repository vocabulary as a learning source, and project identifier candidates. | Implemented for Codex / Claude local sessions and Git repository vocabulary |
| Reuse deterministic developer-term speech rules across initial learning and edit learning. | `DeveloperTermSpeechRules` is used by `AgentHistoryDictionaryLearningUseCase`, `RepositoryVocabularyUseCase`, and `CandidateExtractor`; tests cover inferred `SwiftUI`, `JSON`, project identifier candidates such as `VoiceAgentInput`, and katakana project identifier aliases such as `ボイスエージェントインプット`. `AppSettings.preferredLearningScope` defaults to user scope so global hotkey runtime behavior is not implicitly repository-specific. | Implemented |
| Let approved learning improve later rule-based normalization. | `LearningApprovalUseCase`, `DictionaryLearningUseCase`, tests `testApprovedLearningEntriesAffectNextRuleBasedNormalization` and `testAgentHistoryLearningApprovalEvolvesRuleBasedNormalizationForProjectTerms`, plus `evals/learning-cases.json`, `evals/history-learning-cases.json`, `testLearningEvalCases`, and `testHistoryLearningEvalCases` for approved edit-derived and history-derived dictionary growth. | Implemented |
| Let repeated approvals strengthen existing dictionary entries instead of duplicating them. | `DictionaryLearningUseCase.approveCandidates` updates equivalent entries; test `testApprovingEquivalentCandidateStrengthensExistingDictionaryEntry`. | Implemented |
| Detect likely voice misrecognitions behind a replaceable detector. | `VoiceMisrecognitionDetector`, `RuleBasedVoiceMisrecognitionDetector`, `DetectorBackedLearningCandidateReviewer`, and tests for replaceable detector behavior. | Implemented |
| Keep LLM-style assistance out of STT, deterministic normalization, and default hotkey latency. | `LocalCommandLearningCandidateReviewer` is configured through `Learning Settings...` and called only by `PromptEditLearningUseCase.confirm` in the learning preview path. `docs/contracts/learning-reviewer-command.md` defines stdin/stdout JSON, `VoiceAgentInputApp.interactiveLearningReviewerTimeoutSeconds` keeps interactive review short, and `testPromptEditLearningFallsBackToUnreviewedCandidatesWhenReviewerFails` verifies failed review does not block confirmation. Future LLM-backed implementations must use local Foundation Models only. | Implemented for current local command reviewer; local Foundation Model adapter remains future work |
| Keep dangerous substitutions and reviewer-injected candidates from auto-applying. | `DangerousCommandPolicy`, candidate guardrails in `DetectorBackedLearningCandidateReviewer` and `LocalCommandLearningCandidateReviewer`, plus tests `testLocalCommandLearningCandidateReviewerPreservesDangerousGuardrails` and `testLocalCommandLearningCandidateReviewerDoesNotAutoApplyInjectedCandidates`. | Implemented |
| Keep the bundled local reviewer contract usable. | `scripts/local_learning_reviewer_example.py` provides a deterministic local-only reviewer, and `testBundledLocalLearningReviewerExampleFollowsCommandContract` invokes it through `LocalCommandLearningCandidateReviewer`. | Implemented |
| Preserve fully local privacy. | Local history and local reviewer adapters use filesystem/process boundaries only; privacy validators reject direct network snippets; manual E2E checklist covers raw audio/transcript persistence expectations. Product docs now exclude cloud STT, network LLM calls, and network IO in MVP model education or fallback conversion. | Implemented, manual evidence still needed |
| Support full record-to-stop transcription across pauses as far as Apple Speech snapshots allow. | `SpeechTranscriptAccumulator` merges partial/final snapshots and tests pause-split, overlap, rolling revision, and final-only-last-chunk cases. | Implemented with Apple Speech limitation |

## Remaining Evidence Needed

- Manual macOS E2E evidence for real microphone capture, Apple Speech behavior, Accessibility paste, candidate approval UI, `Learning Settings...`, and local filesystem privacy inspection.
- Real-world trial of a trusted local reviewer command, such as `/usr/bin/python3` plus `scripts/local_learning_reviewer_example.py`, through the app UI.
- App UI wiring for local context model export/import/delete beyond approved dictionary controls.
- Future GitHub, Slack, and Chatwork learning-source adapters.
- Future local Foundation Model adapter for model education and explicit fallback conversion.
- If Apple Speech never emits missing earlier speech in any partial or final snapshot, the current accumulator cannot reconstruct it; that would require chunk-level audio segmentation or another local STT strategy.

## Verification

Automated verification currently runs through:

```text
make check
```

The latest run passed Swift tests, demo smoke, app bundle build, app launch smoke, architecture validators, privacy contract validation, MVP coverage validation, and manual E2E checklist validation.

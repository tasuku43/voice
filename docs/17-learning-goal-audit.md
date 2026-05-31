# Learning Goal Audit

This audit maps the current implementation to the product goal of a mostly rule-based voice input tool that can learn environment-specific vocabulary and optionally use LLM-style review outside the transcription hot path.

## Requirements And Evidence

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Keep ordinary prompt conversion mostly rule-based and fast. | `VoiceInputPipeline` records and transcribes, then `PromptProcessingPipeline` runs `DictionaryPromptNormalizer` and `JapanesePunctuationPromptRefiner`. The optional learning reviewer is invoked from `PromptEditLearningUseCase` after preview confirmation. | Implemented |
| Treat dictionary replacement and prompt refinement as text-to-text layers. | `PromptTextTransform`, `DictionaryPromptTextTransform`, `RefinementPromptTextTransform`, and tests `testPromptTransformsExposeTextToTextConvenience` and `testPromptTextTransformPipelineComposesDictionaryAndRefinementLayers`. | Implemented |
| Learn environment-specific vocabulary from local Codex and Claude history. | `LocalAgentHistoryTextProvider`, `AgentHistoryLearningModeUseCase`, `AgentHistoryDictionaryLearningUseCase`, menu item `Learn From Agent History...`, and tests for bounded local history loading, structured user text extraction, candidate generation, duplicate skipping, repository scope, and project identifier candidates. | Implemented |
| Reuse deterministic developer-term speech rules across initial learning and edit learning. | `DeveloperTermSpeechRules` is used by `AgentHistoryDictionaryLearningUseCase` and `CandidateExtractor`; tests cover inferred `SwiftUI`, `JSON`, and project identifier candidates such as `VoiceAgentInput`. | Implemented |
| Let approved learning improve later rule-based normalization. | `LearningApprovalUseCase`, `DictionaryLearningUseCase`, and tests `testApprovedLearningEntriesAffectNextRuleBasedNormalization` and `testAgentHistoryLearningApprovalEvolvesRuleBasedNormalizationForProjectTerms`. | Implemented |
| Let repeated approvals strengthen existing dictionary entries instead of duplicating them. | `DictionaryLearningUseCase.approveCandidates` updates equivalent entries; test `testApprovingEquivalentCandidateStrengthensExistingDictionaryEntry`. | Implemented |
| Detect likely voice misrecognitions behind a replaceable detector. | `VoiceMisrecognitionDetector`, `RuleBasedVoiceMisrecognitionDetector`, `DetectorBackedLearningCandidateReviewer`, and tests for replaceable detector behavior. | Implemented |
| Keep LLM-style review out of STT and normalization latency. | `LocalCommandLearningCandidateReviewer` is configured through `Learning Settings...` and called only by `PromptEditLearningUseCase.confirm` after preview confirmation. `docs/contracts/learning-reviewer-command.md` defines stdin/stdout JSON, `VoiceAgentInputApp.interactiveLearningReviewerTimeoutSeconds` keeps interactive review short, and `testPromptEditLearningFallsBackToUnreviewedCandidatesWhenReviewerFails` verifies failed review does not block confirmation. | Implemented |
| Keep dangerous substitutions and reviewer-injected candidates from auto-applying. | `DangerousCommandPolicy`, candidate guardrails in `DetectorBackedLearningCandidateReviewer` and `LocalCommandLearningCandidateReviewer`, plus tests `testLocalCommandLearningCandidateReviewerPreservesDangerousGuardrails` and `testLocalCommandLearningCandidateReviewerDoesNotAutoApplyInjectedCandidates`. | Implemented |
| Keep the bundled local reviewer contract usable. | `scripts/local_learning_reviewer_example.py` provides a deterministic local-only reviewer, and `testBundledLocalLearningReviewerExampleFollowsCommandContract` invokes it through `LocalCommandLearningCandidateReviewer`. | Implemented |
| Preserve local-first privacy. | Local history and local reviewer adapters use filesystem/process boundaries only; privacy validators reject direct network snippets; manual E2E checklist covers raw audio/transcript persistence expectations. | Implemented, manual evidence still needed |
| Support full record-to-stop transcription across pauses as far as Apple Speech snapshots allow. | `SpeechTranscriptAccumulator` merges partial/final snapshots and tests pause-split, overlap, rolling revision, and final-only-last-chunk cases. | Implemented with Apple Speech limitation |

## Remaining Evidence Needed

- Manual macOS E2E evidence for real microphone capture, Apple Speech behavior, Accessibility paste, candidate approval UI, `Learning Settings...`, and local filesystem privacy inspection.
- Real-world trial of a trusted local reviewer command, such as `/usr/bin/python3` plus `scripts/local_learning_reviewer_example.py`, through the app UI.
- If Apple Speech never emits missing earlier speech in any partial or final snapshot, the current accumulator cannot reconstruct it; that would require chunk-level audio segmentation or another local STT strategy.

## Verification

Automated verification currently runs through:

```text
make check
```

The latest run passed Swift tests, demo smoke, app bundle build, app launch smoke, architecture validators, privacy contract validation, MVP coverage validation, and manual E2E checklist validation.

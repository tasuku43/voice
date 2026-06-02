# Learning Goal Audit

This audit maps the current implementation to the product goal of a fully local, mostly rule-based voice input tool that can educate a local context model from environment-specific vocabulary. LLM-style assistance must be local Foundation Models only, primarily for model education, and optional as a last-resort conversion stage outside the default hotkey path.

## Requirements And Evidence

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Keep ordinary hotkey dictation mostly rule-based and fast. | `VoiceInputPipeline` records and transcribes, then `PromptProcessingPipeline` runs `DictionaryPromptNormalizer` and `JapanesePunctuationPromptRefiner`. `Quick Paste` is the only normal voice input mode, and the app inserts `result.insertion` directly with no learning reviewer and no candidate approval dialog. | Implemented |
| Treat dictionary replacement and prompt refinement as text-to-text layers. | `PromptTextTransform`, `DictionaryPromptTextTransform`, `RefinementPromptTextTransform`, and tests `testPromptTransformsExposeTextToTextConvenience` and `testPromptTextTransformPipelineComposesDictionaryAndRefinementLayers`. | Implemented |
| Reuse learned context before and after ASR. | `DictionaryEntry` stores `recognitionHints` for ASR-first vocabulary biasing and `spokenForms` for post-STT correction. `LocalContextModel` wraps entries and exposes both `recognitionHints` and `postSTTEntries`. `LocalContextModelDocumentCodec` and `JSONLocalContextModelRepository` provide a versioned local JSON document for the model. `LocalContextModelDataUseCase.rebuildModel(...)` persists the model after learning-source runs, and `DictionaryEntryLoadingUseCase` loads saved model entries into the hotkey runtime. `SpeechRecognitionHintsUseCase` converts loaded `recognitionHints` into bounded `contextualStrings`; `VoiceAgentInputApp.recordVoiceInput()` passes those hints into `AppleSpeechEngine`, while the same entries still feed `NormalizationContext` for fallback correction. Tests cover recognition-hint preference, legacy dictionary decoding, dictionary-to-hint conversion, local context model outputs, local model rebuild/persistence, runtime model loading, and Apple Speech request wiring. | Implemented |
| Educate a local context model from environment-specific sources. | `LearningSource`, `LearningSourceSelection`, `LocalAgentHistoryTextProvider`, `RepositoryVocabularyLearningSource`, `AgentHistoryLearningModeUseCase`, `LocalContextCandidateGenerationUseCase`, `LocalContextModelStatusUseCase`, menu items `Local Context Model Status...` and `Rebuild Local Context Model...`, and tests for bounded local history loading, structured user text extraction, source text counts, candidate generation, duplicate skipping, repository vocabulary as a learning source, local read-only git command enforcement, project identifier candidates, and status warnings when configured repository settings do not match the saved model source kinds. The rebuild action refreshes the runtime local context model without candidate approval, and the status action shows last rebuild time, source kinds, source text counts, generated candidates, runtime entry count, and stale-source warnings without rebuilding. | Implemented for Codex / Claude local sessions and Git repository vocabulary |
| Reuse deterministic developer-term speech rules across source learning. | `DeveloperTermSpeechRules` is used by `LocalContextCandidateGenerationUseCase` and `RepositoryVocabularyUseCase`; tests cover inferred `SwiftUI`, `JSON`, project identifier candidates such as `VoiceAgentInput`, and katakana project identifier aliases such as `ボイスエージェントインプット`. Runtime hotkey behavior is not implicitly repository-specific; repository folders are selected learning sources for bounded model rebuilds. | Implemented |
| Let source learning improve later rule-based normalization. | `AgentHistoryLearningModeUseCase`, `LocalContextModelBuildUseCase`, `DictionaryEntryLoadingUseCase`, `testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms`, `evals/history-learning-cases.json`, and `testHistoryLearningEvalCases` show that learned source terms become saved local context model entries and later post-STT transforms without candidate approval UI. | Implemented |
| Keep candidate generation explainable while separating it from the hotkey app layer. | `CorrectionCandidate`, `LocalContextCandidateGenerationUseCase`, and repository vocabulary learning generate reasons and confidence metadata from explicit local learning sources. Prompt insertion carries only text; it does not return learning candidates. | Implemented |
| Keep LLM-style assistance out of STT, deterministic normalization, and default hotkey latency. | The app no longer exposes a generic learning reviewer command. Future LLM-backed implementations must be local Foundation Model adapters only, used for model education or an explicit last-resort conversion stage rather than the ordinary STT -> system dictionary -> custom dictionary path. | Implemented; local Foundation Model adapter remains future work |
| Keep model education source-driven instead of edit-driven. | The old preview-edit diff candidate extractor has been removed. Model entries now come from explicit local source rebuilds, seed dictionaries, and repository vocabulary adapters rather than opportunistic user edits in the fallback preview. | Implemented |
| Preserve fully local privacy. | Local history adapters use filesystem boundaries only; privacy validators reject direct network snippets; manual E2E checklist covers raw audio/transcript persistence expectations. Product docs now exclude cloud STT, network LLM calls, arbitrary reviewer commands, and network IO in MVP model education or fallback conversion. | Implemented, manual evidence still needed |
| Support full record-to-stop transcription across pauses as far as Apple Speech snapshots allow. | `SpeechTranscriptAccumulator` merges partial/final snapshots and tests pause-split, overlap, rolling revision, and final-only-last-chunk cases. | Implemented with Apple Speech limitation |

## Remaining Evidence Needed

- Manual macOS E2E evidence for real microphone capture, Apple Speech behavior, Accessibility paste, local context model rebuild behavior, and local filesystem privacy inspection.
- Future local archive/cache learning-source adapters for GitHub, Slack, and Chatwork data.
- Future local Foundation Model adapter for model education and explicit fallback conversion.
- Future source freshness checks based on content modification times after the last rebuild.
- If Apple Speech never emits missing earlier speech in any partial or final snapshot, the current accumulator cannot reconstruct it; that would require chunk-level audio segmentation or another local STT strategy.

## Verification

Automated verification currently runs through:

```text
make check
```

The latest run passed Swift tests, demo smoke, app bundle build, app launch smoke, architecture validators, privacy contract validation, MVP coverage validation, and manual E2E checklist validation.

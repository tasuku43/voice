# Learning Goal Audit

This audit maps the current implementation to the product goal of a fully local, mostly rule-based voice input tool that can educate a local context model from environment-specific vocabulary. LLM-style assistance must be local Foundation Models only, primarily for model education or optional post-STT refinement in the shared CLI/hotkey pipeline.

## Requirements And Evidence

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Keep ordinary hotkey dictation mostly rule-based and fast. | `VoiceInputPipeline` records and transcribes, then `PromptProcessingPipeline` runs `DictionaryPromptNormalizer`. `Quick Paste` is the only normal voice input mode, and the app inserts `result.insertion` directly with no learning reviewer or separate review dialog. Foundation Model refinement can be enabled in the shared post-STT pipeline, but it is local-only and not required for the default path. | Implemented |
| Treat dictionary replacement as the default post-STT text layer. | `PromptNormalizer`, `DictionaryPromptNormalizer`, `PromptProcessingPipeline`, and test `testPromptNormalizerExposesTextToTextConvenience`. | Implemented |
| Reuse learned context before and after ASR. | `DictionaryEntry` stores `recognitionHints` for ASR-first vocabulary biasing and `spokenForms` for post-STT correction. `LocalContextModel` wraps entries and exposes both `recognitionHints` and `postSTTEntries`. `LocalContextModelDocumentCodec` and `JSONLocalContextModelRepository` provide a versioned local JSON document for the model. `LocalContextModelRebuildUseCase.rebuild(...)` persists the model after learning-source runs, and `DictionaryEntryLoadingUseCase` loads saved model entries into the hotkey runtime. `SpeechRecognitionHintsUseCase` converts loaded `recognitionHints` into bounded `contextualStrings`; `VoiceAgentInputApp.recordVoiceInput()` passes those hints into `AppleSpeechEngine`, while the same entries still feed `NormalizationContext` for fallback correction. Tests cover recognition-hint preference, legacy dictionary decoding, dictionary-to-hint conversion, local context model outputs, local model rebuild/persistence, runtime model loading, and Apple Speech request wiring. | Implemented |
| Educate a local context model from environment-specific sources. | `LearningSource`, `LearningSourceSelection`, `LocalAgentHistoryTextProvider`, `RepositoryVocabularyLearningSource`, `AgentHistoryLearningModeUseCase`, `LocalContextCandidateGenerationUseCase`, menu item `Rebuild Local Context Model...`, and tests for bounded local history loading, structured user text extraction, source text counts, generated entry extraction, duplicate skipping, repository vocabulary as a learning source, local read-only git command enforcement, and project identifier entries. The rebuild action refreshes the runtime local context model without opening review/approval UI and shows rebuild metadata immediately after the run. | Implemented for Codex / Claude local sessions and Git repository vocabulary |
| Reuse deterministic developer-term speech rules across source learning. | `DeveloperTermSpeechRules` is used by `LocalContextCandidateGenerationUseCase` and `RepositoryVocabularyUseCase`; tests cover inferred `SwiftUI`, `JSON`, project identifier entries such as `VoiceAgentInput`, and katakana project identifier aliases such as `ボイスエージェントインプット`. Runtime hotkey behavior is not implicitly repository-specific; repository folders are selected learning sources for bounded model rebuilds. | Implemented |
| Let source learning improve later rule-based normalization. | `AgentHistoryLearningModeUseCase`, `LocalContextModelBuildUseCase`, `DictionaryEntryLoadingUseCase`, `testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms`, `evals/history-learning-cases.json`, and `testHistoryLearningEvalCases` show that learned source terms become saved local context model entries and later post-STT transforms without review/approval UI. | Implemented |
| Keep generated entries explainable while separating them from the hotkey app layer. | `CorrectionCandidate`, `LocalContextCandidateGenerationUseCase`, and repository vocabulary learning generate reasons and confidence metadata from explicit local learning sources. Prompt insertion carries only text; it does not return learning entries. | Implemented |
| Keep LLM-style assistance out of STT and deterministic normalization. | The app no longer exposes a generic learning reviewer command. LLM-backed implementations must be local Foundation Model adapters only, and they run behind `PromptTextRefiner` after STT and dictionary normalization rather than replacing `AppleSpeechEngine` or `DictionaryPromptNormalizer`. CLI evaluation has shown that this stage is not always superior to deterministic pause smoothing, so it remains explicit and optional. | Implemented |
| Keep model education source-driven instead of edit-driven. | The old edit-derived learning extractor has been removed. Model entries now come from explicit local source rebuilds, seed dictionaries, and repository vocabulary adapters rather than opportunistic edits made during voice input. | Implemented |
| Preserve fully local privacy. | Local history adapters use filesystem boundaries only; privacy validators reject direct network snippets and raw speech snapshot logging callbacks; raw speech snapshots stay inside the STT adapter, and debug logs record completed transcript lengths instead of raw transcript text; manual E2E checklist covers raw audio/transcript persistence expectations, and `make manual-e2e-privacy-inspect` checks Application Support plus the debug log after a real run. Product docs now exclude cloud STT, network LLM calls, arbitrary reviewer commands, and network IO in MVP model education or fallback conversion. | Verified for current source; manual filesystem evidence still needed |
| Support full record-to-stop transcription across pauses as far as Apple Speech results allow. | `AppleSpeechEngine` now uses `SpeechAnalyzer` with `DictationTranscriber` or `SpeechTranscriber` for whole-file transcription after recording stops; result segments are preserved in `TranscriptionResult` while callers that only need final text read `.text`. | Implemented |

## Remaining Completion Evidence

- Manual macOS E2E evidence for real microphone capture, Apple Speech behavior, Accessibility paste, local context model rebuild behavior, and local filesystem privacy inspection with `make manual-e2e-privacy-inspect`.
- If Apple Speech never emits missing earlier speech in any partial or final snapshot, the current accumulator cannot reconstruct it; that would require chunk-level audio segmentation or another local STT strategy.

## Deferred, Not Completion Gates

- Local archive/cache learning-source adapters for GitHub, Slack, and Chatwork data.
- Broader local Foundation Model policy, UI settings, and automatic selection based on fixture evals.
- Source freshness checks based on content modification times after the last rebuild.

## Verification

Automated verification currently runs through:

```text
make check
```

The latest run passed Swift tests, demo smoke, app bundle build, app launch smoke, architecture validators, privacy contract validation, MVP coverage validation, and manual E2E checklist validation.

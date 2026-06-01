#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")


REQUIRED_SNIPPETS = {
    "docs/17-learning-goal-audit.md": [
        "mostly rule-based voice input tool",
        "default `Quick Paste` mode",
        "no learning reviewer and no candidate approval dialog",
        "Reuse learned context before and after ASR.",
        "SpeechRecognitionHintsUseCase",
        "contextualStrings",
        "recognitionHints",
        "legacy dictionary decoding",
        "Educate a local context model from environment-specific sources.",
        "structured user text extraction",
        "project identifier candidates",
        "katakana project identifier aliases",
        "AppSettings.preferredLearningScope",
        "LearningSourceSelection",
        "Train Dictionary From Sources...",
        "source text counts",
        "RepositoryVocabularyLearningSource",
        "global hotkey runtime behavior is not implicitly repository-specific",
        "evals/learning-cases.json",
        "evals/history-learning-cases.json",
        "testLearningEvalCases",
        "testHistoryLearningEvalCases",
        "testAgentHistoryLearningApprovalEvolvesRuleBasedNormalizationForProjectTerms",
        "local Foundation Models only",
        "interactiveLearningReviewerTimeoutSeconds",
        "testPromptEditLearningFallsBackToUnreviewedCandidatesWhenReviewerFails",
        "testBundledLocalLearningReviewerExampleFollowsCommandContract",
        "manual evidence still needed",
    ],
    "docs/contracts/learning.md": [
        "Bounded local Codex/Claude history text",
        "Configured repository vocabulary exposed through a learning-source adapter.",
        "Generate dictionary candidates from local learning sources after explicit user action.",
        "Keep default Quick Paste outside candidate review and approval",
        "Reuse deterministic developer-term speech rules across history learning and edit learning.",
        "Treat repository folders as learning-source configuration",
        "Use the configured preferred learning scope for Learning Preview edit-derived candidates",
        "If candidate review fails, confirmation still returns the prompt and unreviewed candidates",
        "Persist approved entries only after user approval.",
        "Quick Paste remains a fast rule-based insertion path",
    ],
    "docs/contracts/local-context-model.md": [
        "Local Context Model Contract",
        "Recognition hints for STT adapters",
        "Post-STT transform entries",
        "DictionaryEntryLoadingUseCase",
        "local Foundation Model",
        "Network IO",
    ],
    "docs/contracts/learning-reviewer-command.md": [
        "The learning reviewer command is optional.",
        "Do not upload transcripts or candidates.",
        "Do not inject new candidates.",
        "short timeout",
        "falls back to unreviewed candidates",
    ],
    "src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift": [
        ".codex/history.jsonl",
        ".claude/projects",
        "maximumBytesPerFile",
        "userTextFragments",
        "parsedStructuredJSON",
        "contentModificationDate",
    ],
    "src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift": [
        "spokenPhrases",
        "katakanaIdentifierPhrases",
        "spokenIdentifierPhrase",
        "identifierComponents",
    ],
    "src/VoiceAgentInputCore/App/PromptEditLearningUseCase.swift": [
        "candidateReviewer.review",
        "reviewedCandidates = confirmed.candidates",
    ],
    "src/VoiceAgentInputCore/App/SpeechRecognitionHints.swift": [
        "public struct SpeechRecognitionHints",
        "contextualStrings",
        "hints(from entries: [DictionaryEntry])",
        "entry.recognitionHints",
    ],
    "src/VoiceAgentInputCore/App/LocalContextModel.swift": [
        "public struct LocalContextModel",
        "postSTTEntries",
        "recognitionHints",
        "LocalContextModelBuildUseCase",
    ],
    "src/VoiceAgentInputCore/App/LocalContextModelDocumentCodec.swift": [
        "public struct LocalContextModelDocument",
        "schemaVersion",
        "LocalContextModelDocumentCodec",
    ],
    "src/VoiceAgentInputCore/App/LocalContextModelRepository.swift": [
        "public protocol LocalContextModelRepository",
        "LocalContextModelDataUseCase",
        "deleteLocalContextModel",
    ],
    "src/VoiceAgentInputCore/Domain/DictionaryEntry.swift": [
        "recognitionHints",
        "defaultRecognitionHints",
        "decodeIfPresent([String].self, forKey: .recognitionHints)",
    ],
    "src/VoiceAgentInputCore/App/LearningSource.swift": [
        "public protocol LearningSource",
        "public struct LearningText",
        "CorrectionCandidateLearningSource",
    ],
    "src/VoiceAgentInputCore/App/LearningSourceSelection.swift": [
        "public struct LearningSourceSelection",
        "selectedKinds",
    ],
    "src/VoiceAgentInputCore/App/RepositoryVocabularyLearningSource.swift": [
        "RepositoryVocabularyLearningSource",
        "correctionCandidates",
    ],
    "src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift": [
        "recognitionHints",
        "request.contextualStrings = recognitionHints.contextualStrings",
    ],
    "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
        "Learn From Agent History...",
        "Train Dictionary From Sources...",
        "Codex / Claude local sessions",
        "Git repository vocabulary",
        "Learning Settings...",
        "interactiveLearningReviewerTimeoutSeconds",
        "localContextModelRepository: try localContextModelRepository()",
        "recognitionHints: SpeechRecognitionHintsUseCase().hints(from: entries)",
        "VoiceInputModeDecisionUseCase().decide",
    ],
    "src/VoiceAgentInputCore/App/VoiceInputModeDecisionUseCase.swift": [
        "case quickPaste(ConfirmedPrompt)",
        "case learningPreview(PromptPreview)",
        "promptToInsert: preview.correctedPrompt",
        "candidates: []",
    ],
    "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
        "testLocalAgentHistoryTextProviderExtractsUserTextFromStructuredJSONL",
        "testLocalAgentHistoryTextProviderSkipsStructuredJSONWithoutUserText",
        "testLocalAgentHistoryTextProviderPrefersRecentlyModifiedClaudeProjectFiles",
        "testAgentHistoryLearningApprovalEvolvesRuleBasedNormalizationForProjectTerms",
        "testPromptEditLearningFallsBackToUnreviewedCandidatesWhenReviewerFails",
        "testBundledLocalLearningReviewerExampleFollowsCommandContract",
        "testLocalCommandLearningCandidateReviewerDoesNotAutoApplyInjectedCandidates",
        "testVoiceInputModeDecisionKeepsQuickPasteOffTheLearningPath",
        "testSpeechRecognitionHintsUseDictionaryEntriesForContextualStrings",
        "testSpeechRecognitionHintsPreferRecognitionHintsOverCorrectionForms",
        "testLocalLearningDataDocumentCodecDecodesLegacyEntriesWithoutRecognitionHints",
        "testLocalContextModelFeedsRecognitionHintsAndPostSTTEntries",
        "testLocalContextModelCanExcludeGeneratedCandidatesFromRuntimeEntries",
        "testLocalContextModelDocumentCodecRoundTrip",
        "testJSONLocalContextModelRepositoryRoundTripAndDelete",
        "testDictionaryEntryLoadingIncludesSavedLocalContextModelEntries",
        "testDictionaryEntryLoadingDeduplicatesSavedLocalContextModelEntries",
        "testLearningSourceSelectionReportsSelectedKinds",
        "testAgentHistoryLearningModeReportsSourceTextCounts",
        "testAppleSpeechEngineAppliesContextualStringsToRecognitionRequest",
        "testLearningModeCanCombineAgentHistoryAndRepositoryVocabularySources",
        "testRuntimeDictionaryLoadingDefaultsToSeedAndApprovedEntriesOnly",
    ],
    "test/VoiceAgentInputCoreTests/DemoCLITests.swift": [
        "testDemoHistoryLearningModeReadsLocalHistoryWithoutSaving",
        "testDemoHistoryLearningModeCanSkipApprovedDictionaryEntries",
        "testDemoHistoryLearningNormalizeModeShowsApprovedCandidatesAffectLaterRules",
        "learn-history",
        "learn-history-normalize",
        "ProjectSpecificName",
    ],
    "src/VoiceAgentInputDemo/main.swift": [
        "historyLearning",
        "learn-history",
        "learn-history-normalize",
        "approvedDictionaryPath",
        "LocalAgentHistoryTextProvider",
        "generateCandidates(scope: arguments.scope, existingEntries: existingEntries)",
    ],
    "test/VoiceAgentInputCoreTests/EvalHarnessTests.swift": [
        "testLearningEvalCases",
        "testHistoryLearningEvalCases",
        "evals/learning-cases.json",
        "evals/history-learning-cases.json",
    ],
    "evals/history-learning-cases.json": [
        "ProjectSpecificName",
        "project specific name",
        "repository",
    ],
    "evals/learning-cases.json": [
        "VoiceAgentInput",
        "ボイスエージェントインプット",
        "repository",
    ],
    "test/VoiceAgentInputCoreTests/CandidateExtractorTests.swift": [
        "testCandidateExtractionInfersKatakanaProjectIdentifierSpeechRulesFromEditedPrompt",
        "testCandidateExtractionInfersProjectIdentifierSpeechRulesFromEditedPrompt",
        "testCandidateExtractorCanUseReplaceableMisrecognitionDetector",
    ],
    "test/e2e/manual-macos-mvp-checklist.md": [
        "Learn From Agent History...",
        "bounded local Codex/Claude history scanning",
        "history-derived project identifier",
    ],
}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = ROOT / relative_path
        if not path.exists():
            fail(f"missing learning-goal audit file: {relative_path}")
        text = path.read_text()
        missing = [snippet for snippet in snippets if snippet not in text]
        if missing:
            fail(f"{relative_path} missing snippets: {', '.join(missing)}")
    print("learning goal audit ok")


if __name__ == "__main__":
    main()

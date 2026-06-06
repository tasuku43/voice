#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")


REQUIRED_SNIPPETS = {
    "docs/17-learning-goal-audit.md": [
        "mostly rule-based voice input tool",
        "`Quick Paste` is the only normal voice input mode",
        "no learning reviewer or separate review dialog",
        "Foundation Model refinement can be enabled in the shared post-STT pipeline",
        "Reuse learned context before and after ASR.",
        "SpeechRecognitionHintsUseCase",
        "contextualStrings",
        "recognitionHints",
        "LocalContextModelRebuildUseCase.rebuild",
        "legacy dictionary decoding",
        "Educate a local context model from environment-specific sources.",
        "structured user text extraction",
        "project identifier entries",
        "katakana project identifier aliases",
        "LearningSourceSelection",
        "Rebuild Local Context Model...",
        "without opening review/approval UI",
        "source text counts",
        "RepositoryVocabularyLearningSource",
        "Runtime hotkey behavior is not implicitly repository-specific",
        "evals/history-learning-cases.json",
        "testHistoryLearningEvalCases",
        "testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms",
        "local Foundation Models only",
        "Remaining Completion Evidence",
        "Deferred, Not Completion Gates",
        "manual filesystem evidence still needed",
    ],
    "docs/contracts/learning.md": [
        "Bounded local Codex/Claude history text",
        "Configured repository vocabulary exposed through a learning-source adapter.",
        "Generate local context model entries from local learning sources after explicit user action.",
        "Keep Quick Paste outside separate review UI",
        "Reuse deterministic developer-term speech rules across source learning.",
        "Treat repository folders as learning-source configuration",
        "Build local context model entries without review/approval UI.",
        "Quick Paste remains a fast rule-based insertion path",
    ],
    "docs/contracts/local-context-model.md": [
        "Local Context Model Contract",
        "Recognition hints for STT adapters",
        "Post-STT transform entries",
        "DictionaryEntryLoadingUseCase",
        "rebuildModel",
        "local Foundation Model",
        "Network IO",
    ],
    "docs/18-spec-trim-audit.md": [
        "Spec trim audit",
        "hotkey voice input",
        "Any requirement that normal dictation wait for review/approval UI",
        "local Foundation Model adapter",
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
    "src/VoiceAgentInputCore/App/SpeechRecognitionHints.swift": [
        "public struct SpeechRecognitionHints",
        "contextualStrings",
        "hints(from entries: [DictionaryEntry])",
        "entry.recognitionHints",
    ],
    "src/VoiceAgentInputCore/App/LocalContextModel.swift": [
        "public struct LocalContextModel",
        "lastRebuiltAt",
        "sourceKinds",
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
        "LocalContextModelRebuildUseCase",
        "rebuildModel",
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
        "SpeechAnalysisContextBuilder",
        "context.contextualStrings = contextualStrings",
    ],
    "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
        "Model Education",
        "Last rebuild time",
        "Rebuild Local Context Model...",
        "rebuildLocalContextModelFromSources",
        "showLocalContextModelRebuiltAlert",
        "Codex / Claude local sessions",
        "Git repository vocabulary",
        "localContextModelRepository: try localContextModelRepository()",
        "recognitionHints: SpeechRecognitionHintsUseCase().hints(from: entries)",
        "try self.insertPrompt(result.insertion)",
    ],
    "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
        "testLocalAgentHistoryTextProviderExtractsUserTextFromStructuredJSONL",
        "testLocalAgentHistoryTextProviderSkipsStructuredJSONWithoutUserText",
        "testLocalAgentHistoryTextProviderPrefersRecentlyModifiedClaudeProjectFiles",
        "testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms",
        "testSpeechRecognitionHintsUseDictionaryEntriesForContextualStrings",
        "testSpeechRecognitionHintsPreferRecognitionHintsOverCorrectionForms",
        "testLocalContextModelFeedsRecognitionHintsAndPostSTTEntries",
        "testLocalContextModelCanExcludeGeneratedCandidatesFromRuntimeEntries",
        "testLocalContextModelRebuildUseCaseGeneratesCandidatesAndPersistsModel",
        "testLocalContextModelDocumentCodecRoundTrip",
        "testJSONLocalContextModelRepositoryRoundTripAndDelete",
        "testDictionaryEntryLoadingIncludesSavedLocalContextModelEntries",
        "testDictionaryEntryLoadingDeduplicatesSeedAndSavedLocalContextModelEntries",
        "testLearningSourceSelectionReportsSelectedKinds",
        "testAgentHistoryLearningModeReportsSourceTextCounts",
        "testAppleSpeechEngineBuildsAnalysisContextWithTaggedContextualStrings",
        "testLearningModeCanCombineAgentHistoryAndRepositoryVocabularySources",
        "testRuntimeDictionaryLoadingDefaultsToSeedEntriesOnly",
    ],
    "test/VoiceAgentInputCoreTests/DemoCLITests.swift": [
        "testDemoHistoryLearningModeReadsLocalHistoryWithoutSaving",
        "testDemoHistoryLearningNormalizeModeUsesRebuiltModelEntries",
        "learn-history",
        "learn-history-normalize",
        "ProjectSpecificName",
    ],
    "src/VoiceAgentInputDemo/main.swift": [
        "historyLearning",
        "learn-history",
        "learn-history-normalize",
        "LocalAgentHistoryTextProvider",
        "generateCandidates(scope: .user)",
    ],
    "test/VoiceAgentInputCoreTests/EvalHarnessTests.swift": [
        "testHistoryLearningEvalCases",
        "evals/history-learning-cases.json",
    ],
    "evals/history-learning-cases.json": [
        "ProjectSpecificName",
        "project specific name",
        "repository",
    ],
    "test/e2e/manual-macos-mvp-checklist.md": [
        "Rebuild Local Context Model...",
        "without opening review/approval UI",
        "rebuilt local context model",
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

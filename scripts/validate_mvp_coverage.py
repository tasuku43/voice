#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")


REQUIRED_COVERAGE = {
    "hotkey invocation": {
        "src/VoiceAgentInputApp/main.swift": [
            "NSApplication.shared",
            "VoiceAgentInputApp()",
            "app.run()",
        ],
        "src/VoiceAgentInputApp/AppDebugLogger.swift": [
            "VOICE_AGENT_INPUT_DEBUG",
            "debug.log",
        ],
        "src/VoiceAgentInputApp/RecordingFeedbackWindowController.swift": [
            "Getting ready",
            "RecordingWaveformView",
        ],
        "src/VoiceAgentInputCore/App/RecordingFeedbackPresentation.swift": [
            "RecordingFeedbackPresentationUseCase",
            "Listening",
            "Release shortcut to paste",
            "elapsedText",
            "meterLevels",
        ],
        "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
            "testRecordingFeedbackPresentationGuidesPressAndHoldStopToPaste",
            "testRecordingFeedbackPresentationShowsQuietGuidanceAfterVoiceWasDetected",
            "testKeyboardShortcutMonitorStoresConfiguredShortcutAndTrigger",
            "testVoiceInputHotkeyUseCaseUsesPressHoldSemantics",
        ],
        "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
            "AppKitKeyboardShortcutMonitor()",
            "Control-Option-Space",
            "Hotkey Settings...",
            "VoiceInputHotkeyUseCase().action",
            "Stop Voice Input",
            "recordVoiceInput",
            "Open Voice Input Permissions...",
            "Privacy_Accessibility",
            "Privacy_ListenEvent",
        ],
    },
    "record and transcribe": {
        "docs/contracts/audio-capture.md": [
            "Audio Capture Contract",
            "RecordedAudio",
            "Persist raw audio by default",
        ],
        "docs/codex-sessions/audio-capture-session.md": [
            "Audio Capture Session",
            "Return `RecordedAudio` only.",
        ],
        "src/VoiceAgentInputCore/App/VoiceInputPipeline.swift": [
            "func run() async throws -> VoiceInputPipelineResult",
            "audioRecorder.recordOnce",
            "speechEngine.transcribe",
        ],
        "src/VoiceAgentInputCore/App/VoiceInputPipeline.swift": [
            "func run() async throws -> VoiceInputPipelineResult",
            "recordedAudioHandler?(audio)",
        ],
        "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
            "let voiceInputPipeline = VoiceInputPipeline(",
            "let result = try await voiceInputPipeline.run()",
            "recognitionHints: SpeechRecognitionHintsUseCase().hints(from: entries)",
            "localContextModelRepository: try localContextModelRepository()",
        ],
        "src/VoiceAgentInputCore/Infra/AVFoundationAudioRecorder.swift": [
            "AVAudioRecorder",
        ],
        "src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift": [
            "SFSpeechRecognizer",
            "requiresOnDeviceRecognition",
            "request.contextualStrings",
            "SpeechTranscriptAccumulator",
        ],
        "src/VoiceAgentInputCore/App/SpeechRecognitionHints.swift": [
            "public struct SpeechRecognitionHints",
            "contextualStrings",
            "public struct SpeechRecognitionHintsUseCase",
            "entry.recognitionHints",
            "DictionaryEntry",
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
            "LocalContextModelDocument",
            "schemaVersion",
            "LocalContextModelDocumentCodec",
        ],
        "src/VoiceAgentInputCore/App/LocalContextModelRepository.swift": [
            "LocalContextModelRepository",
            "LocalContextModelDataUseCase",
            "rebuildModel",
            "deleteLocalContextModel",
        ],
        "src/VoiceAgentInputCore/Infra/JSONLocalContextModelRepository.swift": [
            "JSONLocalContextModelRepository",
            "saveModel",
            "loadModel",
        ],
        "src/VoiceAgentInputCore/Domain/DictionaryEntry.swift": [
            "recognitionHints",
            "defaultRecognitionHints",
            "decodeIfPresent([String].self, forKey: .recognitionHints)",
        ],
        "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
            "testSpeechRecognitionHintsUseDictionaryEntriesForContextualStrings",
            "testSpeechRecognitionHintsPreferRecognitionHintsOverCorrectionForms",
            "testLocalContextModelFeedsRecognitionHintsAndPostSTTEntries",
            "testLocalContextModelCanExcludeGeneratedCandidatesFromRuntimeEntries",
            "testLocalContextModelRebuildUseCaseGeneratesCandidatesAndPersistsModel",
            "testLocalContextModelDocumentCodecRoundTrip",
            "testJSONLocalContextModelRepositoryRoundTripAndDelete",
            "testDictionaryEntryLoadingIncludesSavedLocalContextModelEntries",
            "testDictionaryEntryLoadingDeduplicatesSeedAndSavedLocalContextModelEntries",
            "testAppleSpeechEngineAppliesContextualStringsToRecognitionRequest",
            "testSpeechTranscriptAccumulatorKeepsEarlierTextWhenFinalOnlyContainsLastChunk",
            "testSpeechTranscriptAccumulatorKeepsJapanesePauseSeparatedPromptWhenFinalOnlyContainsLastSentence",
        ],
    },
    "user-action paste with no submit option": {
        "src/VoiceAgentInputCore/App/PromptInsertionUseCase.swift": [
            "afterUserAction",
            "userActionRequired",
            "TextInsertionRequest(text: prompt.text)",
        ],
        "test/VoiceAgentInputCoreTests/PasteboardInsertionTests.swift": [
            "testPasteboardInsertionWritesPromptTextOnly",
            "testAccessibilityInsertionWritesPasteboardThenSendsPasteCommand",
        ],
    },
    "source learning and model education": {
        "src/VoiceAgentInputCore/App/LocalContextCandidateGenerationUseCase.swift": [
            "LocalContextCandidateGenerationUseCase",
            "candidates(from texts:",
            "local learning sources",
        ],
        "src/VoiceAgentInputCore/App/AgentHistoryTextProvider.swift": [
            "AgentHistoryTextProvider",
            "historyTexts()",
            "LearningSource",
        ],
        "src/VoiceAgentInputCore/App/LearningSource.swift": [
            "LearningSource",
            "LearningText",
            "CorrectionCandidateLearningSource",
        ],
        "src/VoiceAgentInputCore/App/LearningSourceSelection.swift": [
            "LearningSourceSelection",
            "selectedKinds",
            "includeRepositoryVocabulary",
        ],
        "src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift": [
            "AgentHistoryLearningModeUseCase",
            "learningSources",
            "sourceTextCounts",
            "contextCandidateGenerationUseCase.candidates",
            "skippedExistingCandidateCount",
        ],
        "src/VoiceAgentInputCore/App/AppSettings.swift": [
            "preferredLearningScope",
            ".user",
        ],
        "src/VoiceAgentInputCore/App/RepositoryVocabularyLearningSource.swift": [
            "RepositoryVocabularyLearningSource",
            "CorrectionCandidateLearningSource",
        ],
        "src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift": [
            "LocalAgentHistoryTextProvider",
            ".codex/history.jsonl",
            ".claude/projects",
            "maximumBytesPerFile",
            "userTextFragments",
            "contentModificationDate",
            "parsedStructuredJSON",
        ],
        "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
            "Last rebuild time",
            "Rebuild Local Context Model...",
            "rebuildLocalContextModelFromSources",
            "showLocalContextModelRebuiltAlert",
            "promptForLearningSourceSelection",
            "rebuildLocalContextModel(selection:",
            "Codex / Claude local sessions",
            "Git repository vocabulary",
            "LocalAgentHistoryTextProvider",
            "LocalContextModelRebuildUseCase",
            ".rebuild(scope: learningScope, existingEntries: existingEntries)",
            "preferredLearningScope",
        ],
        "docs/17-learning-goal-audit.md": [
            "Learning Goal Audit",
            "Keep ordinary hotkey dictation mostly rule-based and fast.",
            "without candidate approval",
            "testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms",
            "LocalContextModelBuildUseCase",
            "local Foundation Models only",
            "Remaining Evidence Needed",
        ],
        "src/VoiceAgentInputCore/Domain/CorrectionCandidate.swift": [
            "public var reason: String",
        ],
        "src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift": [
            "DeveloperTermSpeechRules",
            "extractTerms(from text:",
            "spokenPhrase(for term:",
            "spokenIdentifierPhrase",
        ],
        "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
            "testLocalContextCandidateGenerationFindsRepeatedDeveloperTerms",
            "testLocalAgentHistoryTextProviderReadsBoundedLocalHistories",
            "testLocalAgentHistoryTextProviderExtractsUserTextFromStructuredJSONL",
            "testLocalAgentHistoryTextProviderSkipsStructuredJSONWithoutUserText",
            "testLocalAgentHistoryTextProviderPrefersRecentlyModifiedClaudeProjectFiles",
            "testAgentHistoryLearningModeUseCaseLoadsHistoryAndGeneratesCandidates",
            "testLearningSourceSelectionReportsSelectedKinds",
            "testAgentHistoryLearningModeReportsSourceTextCounts",
            "testAgentHistoryLearningModeSkipsExistingDictionaryEntries",
            "testAgentHistoryLearningModeCanGenerateRepositoryScopedCandidates",
            "testLearningModeCanCombineAgentHistoryAndRepositoryVocabularySources",
            "testRuntimeDictionaryLoadingDefaultsToSeedEntriesOnly",
            "testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms",
        ],
        "src/VoiceAgentInputCore/App/PromptInsertionUseCase.swift": [
            "public struct PromptInsertion",
            "public init(text: String)",
        ],
        "src/VoiceAgentInputCore/App/LocalContextModel.swift": [
            "learningResult?.candidates.map(Self.entry(from:))",
            "generatedCandidateCount",
        ],
    },
    "local data controls": {
        "src/VoiceAgentInputCore/App/AppSettingsUseCase.swift": [
            "AppSettingsUseCase",
            "saveRepositoryPath",
            "saveVoiceInputHotkey",
        ],
        "src/VoiceAgentInputCore/App/LocalContextModelRepository.swift": [
            "exportModel",
            "importModel",
            "deleteLocalContextModel",
        ],
        "src/VoiceAgentInputCore/App/LocalContextModelDocumentCodec.swift": [
            "LocalContextModelDocumentCodec",
            "dateEncodingStrategy = .iso8601",
            "dateDecodingStrategy = .iso8601",
        ],
        "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
            "Export Local Context Model...",
            "Import Local Context Model...",
            "Open Local Data Folder...",
            "Delete Local Context Model...",
        ],
    },
    "repository vocabulary": {
        "src/VoiceAgentInputCore/App/DictionaryContextLoadingUseCase.swift": [
            "DictionaryContextLoadingUseCase",
            "RepositoryVocabularyFilePathProvider",
        ],
        "src/VoiceAgentInputCore/App/RepositoryVocabularyUseCase.swift": [
            "entries(",
            "scope: .repository",
        ],
        "src/VoiceAgentInputCore/Infra/GitRepositoryContextProvider.swift": [
            "rev-parse",
            "ls-files",
            'guard executable == "/usr/bin/git"',
            "validateLocalReadOnlyGitArguments",
        ],
        "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
            "testGitRepositoryContextProviderReadsRootAndBranch",
            "testGitRepositoryContextProviderReadsBoundedTrackedVocabularyFiles",
            "testProcessCommandRunnerRejectsNonGitExecutable",
            "testProcessCommandRunnerRejectsNetworkCapableGitSubcommands",
        ],
        "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
            "Set Repository Folder...",
        ],
    },
    "privacy and local only": {
        "scripts/validate_architecture_boundaries.py": [
            "Domain boundary violations",
            "App boundary violations",
        ],
        "scripts/validate_privacy_contract.py": [
            "FORBIDDEN_SOURCE_SNIPPETS",
            "requiresOnDeviceRecognition",
        ],
        "src/VoiceAgentInputCore/Infra/TemporaryRecordedAudioFileStore.swift": [
            "removeItem",
        ],
        "test/e2e/manual-macos-mvp-checklist.md": [
            "Privacy",
        ],
    },
    "normalization eval coverage": {
        "scripts/smoke_demo_command.py": [
            "voice-agent-input-demo",
            "demo command smoke ok",
            "learn-history",
            "learn-history-normalize",
            "ProjectSpecificName",
        ],
        "scripts/validate_eval_coverage.py": [
            "MIN_CASES",
            "REQUIRED_EXPECTED_TERMS",
            "eval coverage ok",
        ],
        "evals/normalization-cases.json": [
            "Claude Code",
            "Cursor",
            "GitHub",
        ],
        "evals/history-learning-cases.json": [
            "ProjectSpecificName",
            "project specific name",
            "repository",
        ],
        "test/VoiceAgentInputCoreTests/EvalHarnessTests.swift": [
            "testHistoryLearningEvalCases",
            "evals/history-learning-cases.json",
        ],
    },
    "component contracts and codex sessions": {
        "docs/16-architecture-refactor-summary.md": [
            "Responsibility Moves",
            "App Responsibilities Still Present",
            "Added Contracts",
            "Added Documentation",
            "Next Recommended Session",
        ],
        "src/VoiceAgentInputCore/App/PromptContracts.swift": [
            "normalizeText",
            "NormalizedPrompt",
        ],
        "src/VoiceAgentInputCore/App/PromptProcessingPipeline.swift": [
            "PromptProcessingPipelineResult",
            "PromptProcessingPipeline",
            "process(transcript: Transcript)",
            "PromptInsertion(text: normalized.normalizedText)",
            "normalizer.normalize",
        ],
        "src/VoiceAgentInputCore/App/VoiceInputPipeline.swift": [
            "VoiceInputPipelineResult",
            "transcript",
            "normalizedPrompt",
            "insertion",
            "promptProcessingPipeline().process",
        ],
        "docs/contracts/audio-capture.md": [
            "Audio Capture Contract",
            "Persist raw audio by default",
        ],
        "docs/contracts/voice-input-pipeline.md": [
            "VoiceInputPipelineResult",
            "PromptProcessingPipeline",
            "Stage data",
            "PromptInsertion",
            "built-in vocabulary transform",
            "personal context model transform",
            "optional local Foundation Model fallback",
            "PromptNormalizer.normalizeText",
        ],
        "docs/contracts/local-context-model.md": [
            "Local Context Model Contract",
            "Recognition hints for STT adapters",
            "Post-STT transform entries",
            "rebuildModel",
            "local Foundation Model",
            "Network IO",
        ],
        "docs/18-spec-trim-audit.md": [
            "Spec trim audit",
            "Preview/edit UI has been removed from the current app",
            "Any requirement that the default hotkey path show a preview before insertion",
            "Local context model rebuild/export/import/delete UI is implemented",
            "last rebuild time",
            "local Foundation Model adapter",
        ],
        "docs/codex-sessions/local-context-model-session.md": [
            "Purpose:",
            "local context model",
            "STT recognition hints",
            "post-STT transforms",
        ],
        "docs/codex-sessions/repository-vocabulary-session.md": [
            "bounded repository vocabulary",
            "Do not perform broad uncontrolled recursive scans",
        ],
        "scripts/validate_component_contracts.py": [
            "REQUIRED_CONTRACT_SNIPPETS",
            "REQUIRED_SESSION_SNIPPETS",
            "component contracts ok",
        ],
        "scripts/validate_app_ui_split.py": [
            "PREVIEW_FORBIDDEN",
            "deleted_preview_files",
            "app UI split ok",
        ],
        "scripts/validate_architecture_refactor.py": [
            "REQUIRED_CONTRACTS",
            "REQUIRED_SESSIONS",
            "architecture refactor ok",
        ],
    },
    "manual real app verification": {
        "docs/15-mvp-completion-audit.md": [
            "Remaining completion evidence",
            "Completion rule",
            "eval coverage validation",
            "Architecture boundary validation",
            "Open Voice Input Permissions",
            "Open Local Data Folder",
            "make check",
            "manual macOS MVP report",
        ],
        "scripts/smoke_launch_app_bundle.py": [
            "app launch smoke ok",
            "VoiceAgentInput.app",
        ],
        "test/e2e/manual-macos-mvp-checklist.md": [
            "Quick Paste Voice Input",
            "Accessibility",
            "Local Learning",
            "Repository Vocabulary",
        ],
        "scripts/validate_manual_e2e_checklist.py": [
            "REQUIRED_SNIPPETS",
            "REQUIRED_REPORT_SNIPPETS",
        ],
        "scripts/create_manual_e2e_report.py": [
            "manual-macos-mvp-report-template.md",
            "reports",
        ],
        "test/e2e/manual-macos-mvp-report-template.md": [
            "Run Metadata",
            "Overall result: pass/fail",
            "Quick Paste Voice Input Evidence",
            "Privacy Evidence",
        ],
    },
}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    missing: list[str] = []
    for requirement, files in REQUIRED_COVERAGE.items():
        for relative_path, snippets in files.items():
            path = ROOT / relative_path
            if not path.exists():
                missing.append(f"{requirement}: {relative_path}: missing file")
                continue
            text = path.read_text()
            for snippet in snippets:
                if snippet not in text:
                    missing.append(f"{requirement}: {relative_path}: {snippet}")

    if missing:
        fail("MVP coverage missing snippets: " + ", ".join(missing))

    print("MVP coverage ok")


if __name__ == "__main__":
    main()

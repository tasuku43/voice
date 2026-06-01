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
            "Press shortcut again to paste",
            "elapsedText",
            "meterLevels",
        ],
        "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
            "testRecordingFeedbackPresentationGuidesPressAndHoldStopToPaste",
            "testRecordingFeedbackPresentationShowsQuietToggleGuidanceAfterVoiceWasDetected",
            "testKeyboardShortcutMonitorStoresConfiguredShortcutAndTrigger",
            "testVoiceInputHotkeyUseCaseSupportsPressHoldAndToggleTriggers",
        ],
        "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
            "AppKitKeyboardShortcutMonitor()",
            "Control-Option-Space",
            "Hotkey Settings...",
            "VoiceInputHotkeyUseCase().action",
            "Toggle Recording",
            "recordVoiceInput",
            "Open Voice Input Permissions...",
            "Open Privacy Settings...",
            "Privacy_Accessibility",
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
        "src/VoiceAgentInputCore/App/VoiceInputFlowUseCase.swift": [
            "recordTranscribeAndPreview",
            "VoiceInputPipeline",
        ],
        "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
            "let voiceInputPipeline = VoiceInputPipeline(",
            "let result = try await voiceInputPipeline.run()",
            "recognitionHints: SpeechRecognitionHintsUseCase().hints(from: entries)",
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
        "src/VoiceAgentInputCore/Domain/DictionaryEntry.swift": [
            "recognitionHints",
            "defaultRecognitionHints",
            "decodeIfPresent([String].self, forKey: .recognitionHints)",
        ],
        "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
            "testSpeechRecognitionHintsUseDictionaryEntriesForContextualStrings",
            "testSpeechRecognitionHintsPreferRecognitionHintsOverCorrectionForms",
            "testLocalLearningDataDocumentCodecDecodesLegacyEntriesWithoutRecognitionHints",
            "testAppleSpeechEngineAppliesContextualStringsToRecognitionRequest",
            "testSpeechTranscriptAccumulatorKeepsEarlierTextWhenFinalOnlyContainsLastChunk",
            "testSpeechTranscriptAccumulatorKeepsJapanesePauseSeparatedPromptWhenFinalOnlyContainsLastSentence",
        ],
    },
    "learning preview before insertion": {
        "src/VoiceAgentInputCore/App/PromptPreviewUseCase.swift": [
            "requiresExplicitConfirmation",
            "rawTranscript",
            "correctedPrompt",
        ],
        "src/VoiceAgentInputApp/PreviewWindowController.swift": [
            "Raw transcript",
            "Corrected prompt",
        ],
    },
    "explicit paste without submit": {
        "src/VoiceAgentInputCore/App/PromptInsertionUseCase.swift": [
            "explicitConfirmation",
            "automaticSubmitRejected",
            "submitAutomatically: false",
        ],
        "test/VoiceAgentInputCoreTests/PasteboardInsertionTests.swift": [
            "testAccessibilityInsertionRejectsAutomaticSubmit",
            "testPasteboardInsertionWritesPromptTextOnly",
        ],
    },
    "candidate learning and approval": {
        "src/VoiceAgentInputCore/App/AgentHistoryDictionaryLearningUseCase.swift": [
            "AgentHistoryDictionaryLearningUseCase",
            "candidates(from texts:",
            "local agent history",
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
            "dictionaryLearningUseCase.candidates",
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
            "Learn From Agent History...",
            "Train Dictionary From Sources...",
            "promptForLearningSourceSelection",
            "runDictionaryTraining",
            "Codex / Claude local sessions",
            "Git repository vocabulary",
            "Learning Settings...",
            "LocalAgentHistoryTextProvider",
            "generateCandidates(scope:",
            "preferredLearningScope",
            "saveLearningReviewerCommand",
            "learningReviewerCommandArguments",
            "interactiveLearningReviewerTimeoutSeconds",
        ],
        "docs/contracts/learning-reviewer-command.md": [
            "Learning Reviewer Command Contract",
            "runs only when `Learning Settings...` contains a local executable path",
            "Do not inject new candidates.",
            "short timeout",
            "falls back to unreviewed candidates",
            "scripts/local_learning_reviewer_example.py",
        ],
        "docs/17-learning-goal-audit.md": [
            "Learning Goal Audit",
            "Keep ordinary hotkey dictation mostly rule-based and fast.",
            "interactiveLearningReviewerTimeoutSeconds",
            "testPromptEditLearningFallsBackToUnreviewedCandidatesWhenReviewerFails",
            "testBundledLocalLearningReviewerExampleFollowsCommandContract",
            "testLocalCommandLearningCandidateReviewerDoesNotAutoApplyInjectedCandidates",
            "local Foundation Models only",
            "Remaining Evidence Needed",
        ],
        "scripts/local_learning_reviewer_example.py": [
            "json.load(sys.stdin)",
            "json.dump",
            "autoApplyAllowed",
        ],
        "src/VoiceAgentInputCore/Domain/CorrectionCandidate.swift": [
            "public var reason: String",
        ],
        "src/VoiceAgentInputCore/Domain/VoiceMisrecognitionDetector.swift": [
            "VoiceMisrecognitionDetector",
            "RuleBasedVoiceMisrecognitionDetector",
            "Likely voice misrecognition",
        ],
        "src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift": [
            "DeveloperTermSpeechRules",
            "extractTerms(from text:",
            "spokenPhrase(for term:",
            "spokenIdentifierPhrase",
        ],
        "test/VoiceAgentInputCoreTests/CandidateExtractorTests.swift": [
            "allSatisfy { !$0.reason.isEmpty }",
            "testCandidateExtractionInfersDeveloperTermSpeechRulesFromEditedPrompt",
            "testCandidateExtractionInfersProjectIdentifierSpeechRulesFromEditedPrompt",
            "testCandidateExtractorCanUseReplaceableMisrecognitionDetector",
        ],
        "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
            "testAgentHistoryDictionaryLearningFindsRepeatedDeveloperTerms",
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
            "testRuntimeDictionaryLoadingDefaultsToSeedAndApprovedEntriesOnly",
            "testApprovedLearningEntriesAffectNextRuleBasedNormalization",
            "testAgentHistoryLearningApprovalEvolvesRuleBasedNormalizationForProjectTerms",
            "testApprovingEquivalentCandidateStrengthensExistingDictionaryEntry",
            "testBundledLocalLearningReviewerExampleFollowsCommandContract",
            "testPromptEditLearningFallsBackToUnreviewedCandidatesWhenReviewerFails",
            "testLocalCommandLearningCandidateReviewerTimesOutSlowCommand",
        ],
        "src/VoiceAgentInputCore/App/PromptPreviewUseCase.swift": [
            "normalizationUseCase.learn",
        ],
        "src/VoiceAgentInputCore/App/DictionaryLearningUseCase.swift": [
            "approveCandidates",
            "firstEquivalentIndex",
            "updatedAt",
        ],
        "src/VoiceAgentInputApp/CandidateApprovalDialogController.swift": [
            "Approve dictionary candidates?",
            "Save Selected",
            "candidateDetailText",
            "Confidence",
            "LearningApprovalUseCase(repository: repository).approveSelectedCandidates",
        ],
    },
    "local learning data controls": {
        "src/VoiceAgentInputCore/App/AppSettingsUseCase.swift": [
            "AppSettingsUseCase",
            "saveRepositoryPath",
            "saveRecordingSettings",
        ],
        "src/VoiceAgentInputCore/App/LocalLearningDataUseCase.swift": [
            "exportApprovedEntries",
            "importApprovedEntries",
            "deleteAllLocalLearningData",
        ],
        "src/VoiceAgentInputCore/App/LocalLearningDataDocumentCodec.swift": [
            "LocalLearningDataDocumentCodec",
            "dateEncodingStrategy = .iso8601",
            "dateDecodingStrategy = .iso8601",
        ],
        "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
            "Export Local Dictionary...",
            "Import Local Dictionary...",
            "Open Local Data Folder...",
            "Delete Local Dictionary...",
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
            "requiresExplicitConfirmation",
            "learn-history",
            "learn-history-normalize",
            "ProjectSpecificName",
            "approved-dictionary",
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
        "evals/learning-cases.json": [
            "VoiceAgentInput",
            "ボイスエージェントインプット",
            "repository",
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
            "protocol PromptRefiner",
            "NoOpPromptRefiner",
            "normalizeText",
            "refineText",
            "NormalizedPrompt",
            "RefinedPrompt",
        ],
        "src/VoiceAgentInputCore/App/PromptTextTransform.swift": [
            "protocol PromptTextTransform",
            "PromptTextTransformPipeline",
            "DictionaryPromptTextTransform",
            "RefinementPromptTextTransform",
            "transform(_ text: String) async throws -> String",
        ],
        "src/VoiceAgentInputCore/App/PromptProcessingPipeline.swift": [
            "PromptProcessingPipelineResult",
            "PromptProcessingPipeline",
            "process(transcript: Transcript)",
            "normalizer.normalize",
            "refiner.refine",
        ],
        "src/VoiceAgentInputCore/App/VoiceInputPipeline.swift": [
            "VoiceInputPipelineResult",
            "transcript",
            "normalizedPrompt",
            "refinedPrompt",
            "preview",
            "promptProcessingPipeline().process",
        ],
        "docs/contracts/prompt-refinement.md": [
            "PromptRefiner",
            "NoOpPromptRefiner",
        ],
        "docs/contracts/audio-capture.md": [
            "Audio Capture Contract",
            "Persist raw audio by default",
        ],
        "docs/contracts/voice-input-pipeline.md": [
            "VoiceInputPipelineResult",
            "PromptProcessingPipeline",
            "Stage data",
            "built-in vocabulary transform",
            "personal context model transform",
            "optional local Foundation Model fallback",
            "PromptTextTransform.transform(String) async throws -> String",
        ],
        "docs/codex-sessions/prompt-refinement-session.md": [
            "Purpose",
            "Tests",
            "Done",
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
            "ENTRYPOINT_FORBIDDEN",
            "PREVIEW_REQUIRED",
            "CANDIDATE_APPROVAL_REQUIRED",
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
            "Open Privacy Settings",
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
            "Learning Preview Voice Input",
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
            "Learning Preview Voice Input Evidence",
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

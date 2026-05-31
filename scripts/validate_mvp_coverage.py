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
        "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
            "AppKitKeyboardShortcutMonitor()",
            "Command-Shift-Space",
            "recordVoiceInput",
            "Open Privacy Settings...",
        ],
        "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
            "testKeyboardShortcutMonitorStoresConfiguredShortcutAndTrigger",
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
        ],
        "src/VoiceAgentInputCore/Infra/AVFoundationAudioRecorder.swift": [
            "AVAudioRecorder",
        ],
        "src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift": [
            "SFSpeechRecognizer",
            "requiresOnDeviceRecognition",
        ],
    },
    "preview before insertion": {
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
        "src/VoiceAgentInputCore/Domain/CorrectionCandidate.swift": [
            "public var reason: String",
        ],
        "test/VoiceAgentInputCoreTests/CandidateExtractorTests.swift": [
            "allSatisfy { !$0.reason.isEmpty }",
        ],
        "src/VoiceAgentInputCore/App/PromptPreviewUseCase.swift": [
            "normalizationUseCase.learn",
        ],
        "src/VoiceAgentInputCore/App/DictionaryLearningUseCase.swift": [
            "approveCandidates",
        ],
        "src/VoiceAgentInputApp/CandidateApprovalDialogController.swift": [
            "Approve dictionary candidates?",
            "Save Selected",
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
            "PromptNormalizer.normalizeText",
            "PromptRefiner.refineText",
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
            "Real Voice Input",
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
            "Real Voice Input Evidence",
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

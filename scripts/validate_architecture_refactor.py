#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")

REQUIRED_SNIPPETS = {
    "src/VoiceAgentInputCore/App/PromptContracts.swift": [
        "public struct NormalizedPrompt",
        "public struct RefinedPrompt",
        "public protocol PromptNormalizer",
        "public protocol PromptRefiner",
        "public struct NoOpPromptRefiner",
    ],
    "src/VoiceAgentInputCore/App/Transcript.swift": [
        "public struct Transcript",
    ],
    "src/VoiceAgentInputCore/App/PromptTextTransform.swift": [
        "public protocol PromptTextTransform",
        "PromptTextTransformPipeline",
        "DictionaryPromptTextTransform",
        "RefinementPromptTextTransform",
    ],
    "src/VoiceAgentInputCore/App/VoiceInputPipeline.swift": [
        "public struct VoiceInputPipeline",
        "audioRecorder",
        "speechEngine",
        "promptProcessingPipeline().process",
    ],
    "src/VoiceAgentInputCore/App/PromptProcessingPipeline.swift": [
        "public struct PromptProcessingPipeline",
        "normalizer.normalize",
        "refiner.refine",
    ],
    "src/VoiceAgentInputCore/App/LocalContextModel.swift": [
        "public struct LocalContextModel",
        "postSTTEntries",
        "recognitionHints",
        "public struct LocalContextModelBuildUseCase",
    ],
    "src/VoiceAgentInputCore/App/LocalContextModelDocumentCodec.swift": [
        "public struct LocalContextModelDocument",
        "schemaVersion",
        "LocalContextModelDocumentCodec",
    ],
    "src/VoiceAgentInputCore/App/LocalContextModelRepository.swift": [
        "public protocol LocalContextModelRepository",
        "public struct LocalContextModelDataUseCase",
        "rebuildModel",
        "deleteLocalContextModel",
    ],
    "src/VoiceAgentInputCore/App/DictionaryEntryLoadingUseCase.swift": [
        "public struct DictionaryEntryLoadingUseCase",
        "localContextModelRepository",
        "postSTTEntries",
        "deduplicated",
    ],
    "src/VoiceAgentInputCore/Infra/JSONLocalContextModelRepository.swift": [
        "public struct JSONLocalContextModelRepository",
        "LocalContextModelRepository",
        "saveModel",
    ],
    "src/VoiceAgentInputCore/App/DictionaryContextLoadingUseCase.swift": [
        "public struct DictionaryContextLoadingUseCase",
        "RepositoryVocabularyFilePathProvider",
    ],
    "src/VoiceAgentInputCore/App/LearningApprovalUseCase.swift": [
        "public struct LearningApprovalUseCase",
        "approveSelectedCandidates",
    ],
    "src/VoiceAgentInputCore/App/LocalLearningDataDocumentCodec.swift": [
        "public struct LocalLearningDataDocumentCodec",
        "dateEncodingStrategy = .iso8601",
        "dateDecodingStrategy = .iso8601",
    ],
    "src/VoiceAgentInputCore/Domain/VoiceMisrecognitionDetector.swift": [
        "public protocol VoiceMisrecognitionDetector",
        "public struct RuleBasedVoiceMisrecognitionDetector",
        "Likely voice misrecognition",
    ],
    "src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift": [
        "public enum DeveloperTermSpeechRules",
        "extractTerms(from text:",
        "spokenPhrase(for term:",
        "spokenIdentifierPhrase",
    ],
    "src/VoiceAgentInputCore/App/AppSettingsUseCase.swift": [
        "public struct AppSettingsUseCase",
        "saveRepositoryPath",
        "saveRecordingSettings",
        "saveLearningReviewerCommand",
    ],
    "src/VoiceAgentInputCore/App/PromptEditLearningUseCase.swift": [
        "public protocol LearningCandidateReviewer",
        "public struct PromptEditLearningUseCase",
        "candidateReviewer.review",
        "reviewedCandidates = confirmed.candidates",
    ],
    "src/VoiceAgentInputCore/App/AgentHistoryTextProvider.swift": [
        "public protocol AgentHistoryTextProvider",
        "historyTexts()",
        "LearningSource",
    ],
    "src/VoiceAgentInputCore/App/LearningSource.swift": [
        "public protocol LearningSource",
        "public struct LearningText",
        "public protocol CorrectionCandidateLearningSource",
    ],
    "src/VoiceAgentInputCore/App/LearningSourceSelection.swift": [
        "public struct LearningSourceSelection",
        "selectedKinds",
    ],
    "src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift": [
        "public struct AgentHistoryLearningModeUseCase",
        "learningSources",
        "sourceTextCounts",
        "dictionaryLearningUseCase.candidates",
        "skippedExistingCandidateCount",
    ],
    "src/VoiceAgentInputCore/App/RepositoryVocabularyLearningSource.swift": [
        "public struct RepositoryVocabularyLearningSource",
        "CorrectionCandidateLearningSource",
    ],
    "src/VoiceAgentInputCore/App/AgentHistoryDictionaryLearningUseCase.swift": [
        "public struct AgentHistoryDictionaryLearningUseCase",
        "candidates(from texts:",
        "Found \\(count) uses in local agent history.",
    ],
    "src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift": [
        "public struct LocalAgentHistoryTextProvider",
        ".codex/history.jsonl",
        ".claude/projects",
        "maximumBytesPerFile",
    ],
    "src/VoiceAgentInputCore/Infra/LocalCommandLearningCandidateReviewer.swift": [
        "public struct LocalCommandLearningCandidateReviewer",
        "LocalCommandLearningReviewRequest",
        "process.executableURL",
    ],
    "src/VoiceAgentInputApp/main.swift": [
        "NSApplication.shared",
        "VoiceAgentInputApp()",
        "app.run()",
    ],
    "src/VoiceAgentInputApp/AppDebugLogger.swift": [
        "struct AppDebugLogger",
        "VOICE_AGENT_INPUT_DEBUG",
        "debug.log",
    ],
    "src/VoiceAgentInputApp/RecordingFeedbackWindowController.swift": [
        "final class RecordingFeedbackWindowController",
        "Getting ready",
        "RecordingWaveformView",
    ],
    "src/VoiceAgentInputCore/App/RecordingFeedbackPresentation.swift": [
        "RecordingFeedbackPresentationUseCase",
        "Listening",
        "Release shortcut to paste",
        "Press shortcut again to paste",
        "meterLevels",
        "elapsedText",
    ],
    "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
        "let voiceInputPipeline = VoiceInputPipeline(",
        "let result = try await voiceInputPipeline.run()",
        "learningCandidateReviewer()",
        "Learn From Agent History...",
        "Train Dictionary From Sources...",
        "AgentHistoryLearningModeUseCase",
    ],
    "src/VoiceAgentInputApp/PreviewWindowController.swift": [
        "final class PreviewWindowController",
        "Raw transcript",
        "Corrected prompt",
        "CandidateApprovalDialogController()",
    ],
    "src/VoiceAgentInputApp/CandidateApprovalDialogController.swift": [
        "final class CandidateApprovalDialogController",
        "candidateDetailText",
        "Confidence",
        "LearningApprovalUseCase(repository: repository).approveSelectedCandidates",
    ],
    "docs/16-architecture-refactor-summary.md": [
        "Responsibility Moves",
        "App Responsibilities Still Present",
        "Added Contracts",
        "Added Documentation",
        "Next Recommended Session",
    ],
}

REQUIRED_CONTRACTS = [
    "audio-capture.md",
    "speech-to-text.md",
    "local-context-model.md",
    "normalization.md",
    "prompt-refinement.md",
    "voice-input-pipeline.md",
    "preview-and-approval.md",
    "learning.md",
    "output.md",
]

REQUIRED_SESSIONS = [
    "audio-capture-session.md",
    "speech-to-text-session.md",
    "local-context-model-session.md",
    "normalization-session.md",
    "prompt-refinement-session.md",
    "repository-vocabulary-session.md",
    "preview-ui-session.md",
    "learning-session.md",
    "output-session.md",
]

FORBIDDEN_SNIPPETS = {
    "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
        "final class PreviewWindowController",
        "Raw transcript",
        "Corrected prompt",
        "Approve dictionary candidates?",
    ],
    "src/VoiceAgentInputCore/App/PromptContracts.swift": [
        "import AppKit",
        "import AVFoundation",
        "import Speech",
    ],
    "src/VoiceAgentInputCore/App/PromptProcessingPipeline.swift": [
        "import AppKit",
        "import AVFoundation",
        "import Speech",
    ],
}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def require_snippets() -> None:
    missing: list[str] = []
    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = ROOT / relative_path
        if not path.exists():
            missing.append(f"{relative_path}: missing file")
            continue
        text = path.read_text()
        for snippet in snippets:
            if snippet not in text:
                missing.append(f"{relative_path}: {snippet}")
    if missing:
        fail("architecture refactor missing snippets: " + ", ".join(missing))


def require_files(directory: Path, names: list[str], label: str) -> None:
    missing = [name for name in names if not (directory / name).exists()]
    if missing:
        fail(f"architecture refactor missing {label}: " + ", ".join(missing))


def reject_forbidden() -> None:
    hits: list[str] = []
    for relative_path, snippets in FORBIDDEN_SNIPPETS.items():
        path = ROOT / relative_path
        if not path.exists():
            continue
        text = path.read_text()
        for snippet in snippets:
            if snippet in text:
                hits.append(f"{relative_path}: {snippet}")
    if hits:
        fail("architecture refactor forbidden snippets: " + ", ".join(hits))


def main() -> None:
    require_snippets()
    require_files(ROOT / "docs" / "contracts", REQUIRED_CONTRACTS, "contracts")
    require_files(ROOT / "docs" / "codex-sessions", REQUIRED_SESSIONS, "codex sessions")
    reject_forbidden()
    print("architecture refactor ok")


if __name__ == "__main__":
    main()

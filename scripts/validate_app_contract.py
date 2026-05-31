#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
APP_SOURCE_DIR = ROOT / "src" / "VoiceAgentInputApp"
INFO_PLIST = ROOT / "src" / "VoiceAgentInputApp" / "Info.plist"


REQUIRED_SOURCE_SNIPPETS = [
    "AppKitKeyboardShortcutMonitor()",
    "Command-Shift-Space",
    "Recording Settings...",
    "showRecordingSettings",
    "Permission Status...",
    "PermissionStatusUseCase",
    "Open Privacy Settings...",
    "Learning Settings...",
    "showLearningSettings",
    "saveLearningReviewerCommand",
    "learningReviewerCommandArguments",
    "let audioRecorder = AVFoundationAudioRecorder()",
    "activeAudioRecorder?.stopRecording()",
    "Stop Voice Input",
    "RecordingFeedbackWindowController",
    "currentInputLevel()",
    "Connecting microphone...",
    "Listening",
    "localeIdentifier: settings.effectiveSpeechLocaleIdentifier",
    "requiresOnDeviceRecognition: true",
    "let voiceInputPipeline = VoiceInputPipeline(",
    "let result = try await voiceInputPipeline.run()",
    "learningCandidateReviewer()",
    "LocalCommandLearningCandidateReviewer",
    "interactiveLearningReviewerTimeoutSeconds",
    "correctedTextView.string",
    "PromptInsertionUseCase(insertionController: AccessibilityTextInsertionController())",
    "PasteboardTextInsertionController()",
    "approveCandidatesIfRequested(confirmed.candidates)",
    "candidateDetailText",
    "Confidence",
    "LearningApprovalUseCase(repository: repository).approveSelectedCandidates",
    "Export Local Dictionary...",
    "Import Local Dictionary...",
    "Learn From Agent History...",
    "AgentHistoryLearningModeUseCase",
    "AgentHistoryDictionaryLearningUseCase",
    "preferredLearningScope",
    "Open Local Data Folder...",
    "Delete Local Dictionary...",
    "LocalLearningDataUseCase",
]

REQUIRED_PLIST_KEYS = [
    "NSSpeechRecognitionUsageDescription",
    "NSMicrophoneUsageDescription",
]

FORBIDDEN_SOURCE_SNIPPETS = [
    "http://",
    "https://",
    "URLSession.shared",
]


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    source = "\n".join(
        path.read_text()
        for path in sorted(APP_SOURCE_DIR.glob("*.swift"))
    )
    plist = INFO_PLIST.read_text()

    missing = [snippet for snippet in REQUIRED_SOURCE_SNIPPETS if snippet not in source]
    if missing:
        fail("missing app contract snippets: " + ", ".join(missing))

    missing_plist = [key for key in REQUIRED_PLIST_KEYS if key not in plist]
    if missing_plist:
        fail("missing Info.plist privacy keys: " + ", ".join(missing_plist))

    forbidden = [snippet for snippet in FORBIDDEN_SOURCE_SNIPPETS if snippet in source]
    if forbidden:
        fail("forbidden network snippet in app source: " + ", ".join(forbidden))

    print("app contract ok")


if __name__ == "__main__":
    main()

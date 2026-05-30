#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
APP_SOURCE = ROOT / "src" / "VoiceAgentInputApp" / "main.swift"
INFO_PLIST = ROOT / "src" / "VoiceAgentInputApp" / "Info.plist"


REQUIRED_SOURCE_SNIPPETS = [
    "AppKitKeyboardShortcutMonitor()",
    "Command-Shift-Space",
    "AVFoundationAudioRecorder(durationSeconds: 4)",
    "AppleSpeechEngine(localeIdentifier: \"ja-JP\", requiresOnDeviceRecognition: true)",
    "PreviewWindowController(preview: preview, previewUseCase: previewUseCase)",
    "correctedTextView.string",
    "PromptInsertionUseCase(insertionController: AccessibilityTextInsertionController())",
    "PasteboardTextInsertionController()",
    "approveCandidatesIfRequested(confirmed.candidates)",
    "CandidateApprovalUseCase().approveCandidates",
    "Export Local Dictionary...",
    "Import Local Dictionary...",
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
    source = APP_SOURCE.read_text()
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

#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
APP_SOURCE_DIR = ROOT / "src" / "VoiceAgentInputApp"
INFO_PLIST = ROOT / "src" / "VoiceAgentInputApp" / "Info.plist"


REQUIRED_SOURCE_SNIPPETS = [
    "AppKitKeyboardShortcutMonitor()",
    "Control-Option-Space",
    "Hotkey Settings...",
    "showHotkeySettings",
    "saveVoiceInputHotkey",
    "VoiceInputHotkeyUseCase().action",
    "Toggle Recording",
    "Recording Settings...",
    "Quick Paste Voice Input",
    "showRecordingSettings",
    "Permission Status...",
    "Open Voice Input Permissions...",
    "PermissionStatusUseCase",
    "Input monitoring hotkeys",
    "permission status \\(permissionStatusDescription(status))",
    "permission status changed",
    "requestInputMonitoringAccessIfNeeded",
    "requestAccessibilityAccessIfNeeded",
    "openMissingPermissionSettingsIfNeeded",
    "Privacy_Accessibility",
    "Open Privacy Settings...",
    "Open Input Monitoring Settings...",
    "Local Context Model Status...",
    "showLocalContextModelStatus",
    "Local context model status",
    "Last rebuild time",
    "Status warnings",
    "LocalContextModelStatusUseCase",
    "Rebuild Local Context Model...",
    "rebuildLocalContextModelFromSources",
    "showLocalContextModelRebuiltAlert",
    "Codex / Claude local sessions",
    "Git repository vocabulary",
    "let audioRecorder = AVFoundationAudioRecorder()",
    "activeAudioRecorder?.stopRecording()",
    "Stop Voice Input",
    "Show Push-to-Talk Button",
    "PushToTalkWindowController",
    "RecordingFeedbackWindowController",
    "currentInputLevel()",
    "Getting ready",
    "RecordingFeedbackPresentationUseCase",
    "RecordingWaveformView",
    "elapsedSeconds",
    "localeIdentifier: settings.effectiveSpeechLocaleIdentifier",
    "requiresOnDeviceRecognition: true",
    "recognitionHints: SpeechRecognitionHintsUseCase().hints(from: entries)",
    "let voiceInputPipeline = VoiceInputPipeline(",
    "let result = try await voiceInputPipeline.run()",
    "mode=quickPaste",
    "promptToInsert: result.preview.correctedPrompt",
    "suggestedLearningScope: learningScope",
    "suggestedScope: suggestedLearningScope",
    "correctedTextView.string",
    "PromptInsertionUseCase(insertionController: AccessibilityTextInsertionController())",
    "PasteboardTextInsertionController()",
    "approveCandidatesIfRequested(confirmed.candidates)",
    "candidateDetailText",
    "Confidence",
    "LearningApprovalUseCase(repository: repository).approveSelectedCandidates",
    "Export Local Dictionary...",
    "Import Local Dictionary...",
    "Export Local Context Model...",
    "Import Local Context Model...",
    "LocalContextModelDocumentCodec",
    "LearningSourceSelection",
    "AgentHistoryLearningModeUseCase",
    "AgentHistoryDictionaryLearningUseCase",
    "LocalContextModelDataUseCase",
    "rebuildModel(learningResult: result)",
    "local context model rebuilt",
    "preferredLearningScope",
    "Open Local Data Folder...",
    "Delete Local Dictionary...",
    "Delete Local Context Model...",
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


def source_between(source: str, start: str, end: str) -> str:
    start_index = source.find(start)
    if start_index == -1:
        fail(f"missing source boundary: {start}")
    end_index = source.find(end, start_index)
    if end_index == -1:
        fail(f"missing source boundary after {start}: {end}")
    return source[start_index:end_index]


def validate_quick_paste_learning_boundary(source: str) -> None:
    record_flow = source_between(
        source,
        "@objc private func recordVoiceInput()",
        "private func startVoiceInputFromShortcut()",
    )
    quick_paste_to_fallback = source_between(
        record_flow,
        "promptToInsert: result.preview.correctedPrompt",
        "recordVoiceInput paste failed",
    )
    if "PromptEditLearningUseCase(" in quick_paste_to_fallback:
        fail("Quick Paste recording flow must not construct edit-learning before paste fallback")

    open_preview = source_between(
        source,
        "private func openPreview(preview: PromptPreview, previewUseCase: PromptPreviewUseCase)",
        "private func insertConfirmedPrompt",
    )
    if "PromptEditLearningUseCase(" not in open_preview:
        fail("Edit learning must stay attached to the editable preview path")


def validate_quick_paste_label(source: str) -> None:
    install_menu = source_between(
        source,
        "private func installMenuBarItem()",
        "private func showLaunchWindow",
    )
    if 'NSMenuItem(title: "Quick Paste Voice Input"' not in install_menu:
        fail("default menu label must present Quick Paste as the daily voice input action")

    update_state = source_between(
        source,
        "private func updateRecordingState()",
        "@objc private func showPushToTalkButton()",
    )
    required_label_snippets = [
        '"Quick Paste Voice Input"',
        '"Quick Paste"',
    ]
    missing = [snippet for snippet in required_label_snippets if snippet not in update_state]
    if missing:
        fail("recording state must keep Quick Paste as the daily voice input label: " + ", ".join(missing))


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

    validate_quick_paste_learning_boundary(source)
    validate_quick_paste_label(source)

    print("app contract ok")


if __name__ == "__main__":
    main()

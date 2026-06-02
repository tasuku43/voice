#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
APP_DIR = ROOT / "src" / "VoiceAgentInputApp"
MAIN = APP_DIR / "main.swift"
ENTRYPOINT = APP_DIR / "VoiceAgentInputApp.swift"
PREVIEW = APP_DIR / "PreviewWindowController.swift"

MAIN_REQUIRED = [
    "NSApplication.shared",
    "VoiceAgentInputApp()",
    "app.run()",
]

ENTRYPOINT_REQUIRED = [
    "installMenuBarItem",
    "recordVoiceInput",
    "openPreview(fallback:",
]

ENTRYPOINT_FORBIDDEN = [
    "final class PreviewWindowController",
    "Raw transcript",
    "Corrected prompt",
    "Approve dictionary candidates?",
    "CandidateApprovalDialogController",
]

PREVIEW_REQUIRED = [
    "final class PreviewWindowController",
    "Raw transcript",
    "Corrected prompt",
    "highlightedString",
    "NSColor.systemYellow.withAlphaComponent(0.24)",
    "PromptInsertionUseCase(insertionController: AccessibilityTextInsertionController())",
]

PREVIEW_FORBIDDEN = [
    "Approve dictionary candidates?",
    "CandidateApprovalDialogController",
    "approveCandidatesIfRequested",
]


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not MAIN.exists():
        fail(f"missing app main: {MAIN}")
    if not ENTRYPOINT.exists():
        fail(f"missing app delegate: {ENTRYPOINT}")
    if not PREVIEW.exists():
        fail(f"missing preview controller: {PREVIEW}")

    main_source = MAIN.read_text()
    entrypoint = ENTRYPOINT.read_text()
    preview = PREVIEW.read_text()

    missing_main = [
        snippet for snippet in MAIN_REQUIRED
        if snippet not in main_source
    ]
    if missing_main:
        fail("app main missing snippets: " + ", ".join(missing_main))

    missing_entrypoint = [
        snippet for snippet in ENTRYPOINT_REQUIRED
        if snippet not in entrypoint
    ]
    if missing_entrypoint:
        fail("app delegate missing snippets: " + ", ".join(missing_entrypoint))

    forbidden_entrypoint = [
        snippet for snippet in ENTRYPOINT_FORBIDDEN
        if snippet in entrypoint
    ]
    if forbidden_entrypoint:
        fail("app entrypoint contains preview UI snippets: " + ", ".join(forbidden_entrypoint))

    missing_preview = [
        snippet for snippet in PREVIEW_REQUIRED
        if snippet not in preview
    ]
    if missing_preview:
        fail("preview controller missing snippets: " + ", ".join(missing_preview))

    forbidden_preview = [
        snippet for snippet in PREVIEW_FORBIDDEN
        if snippet in preview
    ]
    if forbidden_preview:
        fail("preview controller contains candidate approval snippets: " + ", ".join(forbidden_preview))

    print("app UI split ok")


if __name__ == "__main__":
    main()

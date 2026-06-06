#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
APP_DIR = ROOT / "src" / "VoiceAgentInputApp"
CORE_APP_DIR = ROOT / "src" / "VoiceAgentInputCore" / "App"
MAIN = APP_DIR / "main.swift"
ENTRYPOINT = APP_DIR / "VoiceAgentInputApp.swift"

MAIN_REQUIRED = [
    "NSApplication.shared",
    "VoiceAgentInputApp()",
    "app.run()",
]

ENTRYPOINT_REQUIRED = [
    "installMenuBarItem",
    "recordVoiceInput",
    "insertPrompt(result.insertion)",
]

PREVIEW_FORBIDDEN = [
    "PreviewFallback",
    "PreviewFallbackUseCase",
    "PreviewWindowController",
    "openPreview",
    "Raw transcript",
    "Corrected prompt",
    "correctedTextView",
]

CANDIDATE_UI_FORBIDDEN = [
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

    deleted_preview_files = [
        APP_DIR / "PreviewWindowController.swift",
        CORE_APP_DIR / "PreviewFallbackUseCase.swift",
    ]
    existing_preview_files = [str(path.relative_to(ROOT)) for path in deleted_preview_files if path.exists()]
    if existing_preview_files:
        fail("preview fallback files should not exist: " + ", ".join(existing_preview_files))

    main_source = MAIN.read_text()
    entrypoint = ENTRYPOINT.read_text()
    app_sources = "\n".join(path.read_text() for path in sorted(APP_DIR.glob("*.swift")))

    missing_main = [snippet for snippet in MAIN_REQUIRED if snippet not in main_source]
    if missing_main:
        fail("app main missing snippets: " + ", ".join(missing_main))

    missing_entrypoint = [snippet for snippet in ENTRYPOINT_REQUIRED if snippet not in entrypoint]
    if missing_entrypoint:
        fail("app delegate missing snippets: " + ", ".join(missing_entrypoint))

    forbidden_preview = [snippet for snippet in PREVIEW_FORBIDDEN if snippet in app_sources]
    if forbidden_preview:
        fail("app source contains preview fallback snippets: " + ", ".join(forbidden_preview))

    forbidden_candidate_ui = [snippet for snippet in CANDIDATE_UI_FORBIDDEN if snippet in app_sources]
    if forbidden_candidate_ui:
        fail("app source contains review/approval UI snippets: " + ", ".join(forbidden_candidate_ui))

    print("app UI split ok")


if __name__ == "__main__":
    main()

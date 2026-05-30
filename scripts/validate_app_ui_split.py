#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
APP_DIR = ROOT / "src" / "VoiceAgentInputApp"
ENTRYPOINT = APP_DIR / "VoiceAgentInputApp.swift"
PREVIEW = APP_DIR / "PreviewWindowController.swift"
CANDIDATE_APPROVAL = APP_DIR / "CandidateApprovalDialogController.swift"

ENTRYPOINT_REQUIRED = [
    "@main",
    "installMenuBarItem",
    "recordVoiceInput",
    "PreviewWindowController(preview: preview, previewUseCase: previewUseCase)",
]

ENTRYPOINT_FORBIDDEN = [
    "final class PreviewWindowController",
    "Raw transcript",
    "Corrected prompt",
    "Approve dictionary candidates?",
    "LearningApprovalUseCase(repository: repository).approveSelectedCandidates",
]

PREVIEW_REQUIRED = [
    "final class PreviewWindowController",
    "Raw transcript",
    "Corrected prompt",
    "PromptInsertionUseCase(insertionController: AccessibilityTextInsertionController())",
    "CandidateApprovalDialogController()",
    "candidateApprovalDialog.approveCandidatesIfRequested",
]

PREVIEW_FORBIDDEN = [
    "LearningApprovalUseCase(repository: repository).approveSelectedCandidates",
    "Approve dictionary candidates?",
]

CANDIDATE_APPROVAL_REQUIRED = [
    "final class CandidateApprovalDialogController",
    "Approve dictionary candidates?",
    "Save Selected",
    "Dangerous command candidates are not selected by default.",
    "LearningApprovalUseCase(repository: repository).approveSelectedCandidates",
]


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not ENTRYPOINT.exists():
        fail(f"missing app entrypoint: {ENTRYPOINT}")
    if not PREVIEW.exists():
        fail(f"missing preview controller: {PREVIEW}")
    if not CANDIDATE_APPROVAL.exists():
        fail(f"missing candidate approval dialog controller: {CANDIDATE_APPROVAL}")

    entrypoint = ENTRYPOINT.read_text()
    preview = PREVIEW.read_text()
    candidate_approval = CANDIDATE_APPROVAL.read_text()

    missing_entrypoint = [
        snippet for snippet in ENTRYPOINT_REQUIRED
        if snippet not in entrypoint
    ]
    if missing_entrypoint:
        fail("app entrypoint missing snippets: " + ", ".join(missing_entrypoint))

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

    missing_candidate_approval = [
        snippet for snippet in CANDIDATE_APPROVAL_REQUIRED
        if snippet not in candidate_approval
    ]
    if missing_candidate_approval:
        fail("candidate approval dialog missing snippets: " + ", ".join(missing_candidate_approval))

    print("app UI split ok")


if __name__ == "__main__":
    main()

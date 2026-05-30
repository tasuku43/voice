#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
CHECKLIST = ROOT / "test" / "e2e" / "manual-macos-mvp-checklist.md"
REPORT_TEMPLATE = ROOT / "test" / "e2e" / "manual-macos-mvp-report-template.md"
REPORT_CREATOR = ROOT / "scripts" / "create_manual_e2e_report.py"
MAKEFILE = ROOT / "Makefile"


REQUIRED_SNIPPETS = [
    "Permission Status...",
    "Open Privacy Settings...",
    "Recording Settings...",
    "Mock Preview",
    "Command-Shift-Space",
    "Record Voice Input",
    "raw transcript",
    "corrected prompt",
    "Claude Code",
    "TypeScript",
    "no automatic submit",
    "Accessibility",
    "copies the prompt",
    "dictionary candidates",
    "Export Local Dictionary...",
    "Import Local Dictionary...",
    "Open Local Data Folder...",
    "Delete Local Dictionary...",
    "Set Repository Folder...",
    "raw audio",
    "raw transcripts are not written",
]

REQUIRED_REPORT_SNIPPETS = [
    "Run Metadata",
    "Overall result: pass/fail",
    "Permission Status Evidence",
    "Recording Settings Evidence",
    "Mock Preview Safety Evidence",
    "Real Voice Input Evidence",
    "Local Learning Evidence",
    "Local Data Controls Evidence",
    "Repository Vocabulary Evidence",
    "Privacy Evidence",
    "No automatic submit",
    "Raw transcripts are not written",
    "No network/cloud prompt observed",
]

REQUIRED_REPORT_CREATOR_SNIPPETS = [
    "manual-macos-mvp-report-template.md",
    "test\" / \"e2e\" / \"reports",
    "Date:",
]

REQUIRED_REPORT_VALIDATOR_SNIPPETS = [
    "Overall result",
    "pass/fail",
    "manual E2E report ok",
]

REQUIRED_MAKEFILE_SNIPPETS = [
    "manual-e2e-report",
    "scripts/create_manual_e2e_report.py",
    "validate-manual-e2e-report",
    "scripts/validate_manual_e2e_report.py",
]


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not CHECKLIST.exists():
        fail(f"missing manual E2E checklist: {CHECKLIST}")
    if not REPORT_TEMPLATE.exists():
        fail(f"missing manual E2E report template: {REPORT_TEMPLATE}")
    if not REPORT_CREATOR.exists():
        fail(f"missing manual E2E report creator: {REPORT_CREATOR}")
    report_validator = ROOT / "scripts" / "validate_manual_e2e_report.py"
    if not report_validator.exists():
        fail(f"missing manual E2E report validator: {report_validator}")

    text = CHECKLIST.read_text()
    missing = [snippet for snippet in REQUIRED_SNIPPETS if snippet not in text]
    if missing:
        fail("manual E2E checklist missing snippets: " + ", ".join(missing))

    report_text = REPORT_TEMPLATE.read_text()
    missing_report = [
        snippet for snippet in REQUIRED_REPORT_SNIPPETS
        if snippet not in report_text
    ]
    if missing_report:
        fail("manual E2E report template missing snippets: " + ", ".join(missing_report))

    creator_text = REPORT_CREATOR.read_text()
    missing_creator = [
        snippet for snippet in REQUIRED_REPORT_CREATOR_SNIPPETS
        if snippet not in creator_text
    ]
    if missing_creator:
        fail("manual E2E report creator missing snippets: " + ", ".join(missing_creator))

    validator_text = report_validator.read_text()
    missing_validator = [
        snippet for snippet in REQUIRED_REPORT_VALIDATOR_SNIPPETS
        if snippet not in validator_text
    ]
    if missing_validator:
        fail("manual E2E report validator missing snippets: " + ", ".join(missing_validator))

    makefile_text = MAKEFILE.read_text()
    missing_makefile = [
        snippet for snippet in REQUIRED_MAKEFILE_SNIPPETS
        if snippet not in makefile_text
    ]
    if missing_makefile:
        fail("Makefile missing manual E2E report snippets: " + ", ".join(missing_makefile))

    print("manual E2E checklist ok")


if __name__ == "__main__":
    main()

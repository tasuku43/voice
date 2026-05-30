#!/usr/bin/env python3
from pathlib import Path
import re
import sys


REQUIRED_METADATA_FIELDS = [
    "Date",
    "Tester",
    "macOS version",
    "Hardware",
    "Build command",
    "App path",
    "Target text app",
    "Accessibility trusted",
    "Microphone status before run",
    "Speech recognition status before run",
]

REQUIRED_SECTIONS = [
    "Setup Evidence",
    "Permission Status Evidence",
    "Recording Settings Evidence",
    "Mock Preview Safety Evidence",
    "Real Voice Input Evidence",
    "Local Learning Evidence",
    "Local Data Controls Evidence",
    "Repository Vocabulary Evidence",
    "Privacy Evidence",
]

EVIDENCE_VALUE_RE = re.compile(r"^- (?P<label>[^:]+): (?P<value>.+)$")


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def field_value(text: str, field: str) -> str | None:
    pattern = re.compile(rf"^- {re.escape(field)}:\s*(.*)$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        return None
    return match.group(1).strip()


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: validate_manual_e2e_report.py <completed-report.md>")

    report_path = Path(sys.argv[1])
    if not report_path.exists():
        fail(f"missing manual E2E report: {report_path}")

    text = report_path.read_text()
    unresolved = [
        marker for marker in ["pass/fail", "pass/fail/not applicable", "yes/no"]
        if marker in text
    ]
    if unresolved:
        fail("manual E2E report still contains placeholders: " + ", ".join(unresolved))

    missing_sections = [
        section for section in REQUIRED_SECTIONS
        if f"## {section}" not in text
    ]
    if missing_sections:
        fail("manual E2E report missing sections: " + ", ".join(missing_sections))

    empty_metadata = [
        field for field in REQUIRED_METADATA_FIELDS
        if not field_value(text, field)
    ]
    if empty_metadata:
        fail("manual E2E report missing metadata: " + ", ".join(empty_metadata))

    overall = field_value(text, "Overall result")
    if overall != "pass":
        fail("manual E2E report overall result must be pass")

    blocking = field_value(text, "Blocking failures")
    if blocking and blocking.lower() not in ["none", "n/a", "not applicable"]:
        fail("manual E2E report has blocking failures")

    failed_lines: list[str] = []
    for line in text.splitlines():
        match = EVIDENCE_VALUE_RE.match(line)
        if not match:
            continue
        label = match.group("label")
        value = match.group("value").strip().lower()
        if label in REQUIRED_METADATA_FIELDS:
            continue
        if label in ["Overall result", "Blocking failures", "Follow-up issues"]:
            continue
        if label in ["Notes", "Screenshots", "Exported dictionary path", "Completed checklist path", "Related issue or PR"]:
            continue
        if value == "fail":
            failed_lines.append(line)

    if failed_lines:
        fail("manual E2E report contains failing evidence:\n" + "\n".join(failed_lines))

    print("manual E2E report ok")


if __name__ == "__main__":
    main()

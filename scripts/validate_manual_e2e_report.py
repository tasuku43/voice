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
    "Quick Paste Voice Input Evidence",
    "Learning Preview Voice Input Evidence",
    "Local Learning Evidence",
    "Local Data Controls Evidence",
    "Repository Vocabulary Evidence",
    "Privacy Evidence",
]

REQUIRED_EVIDENCE_LABELS = [
    "Default mode is Quick Paste",
    "Mode switched back to Quick Paste before daily flow",
    "Custom voice input hotkey saved and menu label updated",
    "Toggle Recording mode starts and stops from the same hotkey",
    "Default Control-Option-Space Press and Hold restored before mode flows",
    "Debug launch used `--debug`",
    "Debug log created at `~/Library/Logs/VoiceAgentInput/debug.log`",
    "`Open Voice Input Permissions...` opens missing permission settings",
    "`Quick Paste Voice Input` menu action works",
    "Push-to-talk release or stop explicitly confirms paste",
    "Toggle hotkey stop explicitly confirms paste",
    "No raw/corrected preview window appears in Quick Paste",
    "No dictionary candidate approval UI appears in Quick Paste",
    "Pasted or copied prompt contains expected developer terms",
    "Debug log contains mode=quickPaste for completed recording",
    "Debug log summary includes mode=quickPaste",
    "Learning Preview mode selected",
    "`Record Learning Preview` menu action works in Learning Preview",
    "Raw transcript visible",
    "Corrected prompt contains expected developer terms",
    "Edited prompt inserted only after preview confirmation",
    "Dictionary candidates shown only after preview confirmation when expected",
    "Debug log contains mode=learningPreview for completed recording",
    "Debug log summary includes mode=learningPreview",
    "Optional trusted local reviewer command runs only after preview confirmation in Learning Preview",
    "Trusted local reviewer command does not run during Quick Paste",
    "Learning Preview edit-derived candidate uses user scope by default even when repository folder is configured",
    "Rebuild Local Context Model works without candidate approval and shows rebuild metadata",
    "Train Dictionary From Sources presents selectable local sources",
    "Learn From Agent History presents bounded Codex/Claude candidates",
    "History-derived project identifier affects later rule-based normalization",
    "Export Local Dictionary works",
    "Export Local Context Model works",
    "Exported Local Context Model contains schemaVersion, model, lastRebuiltAt, and sourceKinds",
    "Import Local Context Model works",
    "Delete Local Context Model works",
    "Raw transcripts are not written to Application Support by default",
    "Debug log is diagnostics only, not local learning data",
    "No network/cloud prompt observed",
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

    missing_labels = [
        label for label in REQUIRED_EVIDENCE_LABELS
        if field_value(text, label) is None
    ]
    if missing_labels:
        fail("manual E2E report missing evidence labels: " + ", ".join(missing_labels))

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

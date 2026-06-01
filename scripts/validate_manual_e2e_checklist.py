#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
CHECKLIST = ROOT / "test" / "e2e" / "manual-macos-mvp-checklist.md"
REPORT_TEMPLATE = ROOT / "test" / "e2e" / "manual-macos-mvp-report-template.md"
REPORT_CREATOR = ROOT / "scripts" / "create_manual_e2e_report.py"
LOG_SUMMARIZER = ROOT / "scripts" / "summarize_debug_log.py"
DEBUG_LAUNCHER = ROOT / "scripts" / "launch_manual_e2e_app.py"
README = ROOT / "test" / "e2e" / "README.md"
MAKEFILE = ROOT / "Makefile"


REQUIRED_SNIPPETS = [
    "Permission Status...",
    "--debug",
    "debug.log",
    "make manual-e2e-launch",
    "Open Voice Input Permissions...",
    "Open Privacy Settings...",
    "Recording Settings...",
    "Hotkey Settings...",
    "Voice Input Mode...",
    "Quick Paste",
    "Learning Preview",
    "Mock Preview",
    "Control-Option-Space",
    "Quick Paste Voice Input",
    "Record Learning Preview",
    "explicit stop acts as the confirmation for paste",
    "Toggle Recording",
    "toggle stop explicitly confirms paste",
    "mode=quickPaste",
    "mode=learningPreview",
    "python3 scripts/summarize_debug_log.py",
    "no raw/corrected preview window appears",
    "no dictionary candidate approval UI appears",
    "raw transcript",
    "corrected prompt",
    "Claude Code",
    "TypeScript",
    "no automatic submit",
    "Accessibility",
    "copies the prompt",
    "dictionary candidates",
    "Learning Settings...",
    "trusted local reviewer command",
    "does not run during `Quick Paste`",
    "candidate is still suggested with user scope by default",
    "Rebuild Local Context Model...",
    "without opening candidate approval",
    "Train Dictionary From Sources...",
    "Codex / Claude local sessions",
    "Git repository vocabulary",
    "Learn From Agent History...",
    "bounded local Codex/Claude history scanning",
    "history-derived project identifier",
    "Export Local Dictionary...",
    "Import Local Dictionary...",
    "Export Local Context Model...",
    "Import Local Context Model...",
    "Open Local Data Folder...",
    "Delete Local Dictionary...",
    "Delete Local Context Model...",
    "Set Repository Folder...",
    "raw audio",
    "raw transcripts are not written",
]

REQUIRED_REPORT_SNIPPETS = [
    "Run Metadata",
    "Overall result: pass/fail",
    "Permission Status Evidence",
    "Recording Settings Evidence",
    "Custom voice input hotkey saved and menu label updated",
    "Toggle Recording mode starts and stops from the same hotkey",
    "Mock Preview Safety Evidence",
    "Quick Paste Voice Input Evidence",
    "Learning Preview Voice Input Evidence",
    "Local Learning Evidence",
    "Default mode is Quick Paste",
    "Debug log created at `~/Library/Logs/VoiceAgentInput/debug.log`",
    "No raw/corrected preview window appears in Quick Paste",
    "`Quick Paste Voice Input` menu action works",
    "`Record Learning Preview` menu action works in Learning Preview",
    "No dictionary candidate approval UI appears in Quick Paste",
    "Debug log contains mode=quickPaste for completed recording",
    "Debug log summary includes mode=quickPaste",
    "Toggle hotkey stop explicitly confirms paste",
    "Debug log contains mode=learningPreview for completed recording",
    "Debug log summary includes mode=learningPreview",
    "Trusted local reviewer command does not run during Quick Paste",
    "Learning Preview edit-derived candidate uses user scope by default even when repository folder is configured",
    "Learn From Agent History presents bounded Codex/Claude candidates",
    "History-derived project identifier affects later rule-based normalization",
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
    "REQUIRED_EVIDENCE_LABELS",
    "No raw/corrected preview window appears in Quick Paste",
    "No dictionary candidate approval UI appears in Quick Paste",
    "Debug log contains mode=quickPaste for completed recording",
    "Debug log summary includes mode=quickPaste",
    "Debug log contains mode=learningPreview for completed recording",
    "Debug log summary includes mode=learningPreview",
    "Learning Preview edit-derived candidate uses user scope by default even when repository folder is configured",
    "Dictionary candidates shown only after preview confirmation when expected",
    "Quick Paste Voice Input Evidence",
    "Learning Preview Voice Input Evidence",
    "manual E2E report ok",
]

REQUIRED_MAKEFILE_SNIPPETS = [
    "manual-e2e-launch",
    "scripts/launch_manual_e2e_app.py",
    "manual-e2e-report",
    "scripts/create_manual_e2e_report.py",
    "validate-manual-e2e-report",
    "scripts/validate_manual_e2e_report.py",
]

REQUIRED_README_SNIPPETS = [
    "make manual-e2e-report",
    "make manual-e2e-launch",
    "open -n .build/VoiceAgentInput.app --args --debug",
    "~/Library/Logs/VoiceAgentInput/debug.log",
    "python3 scripts/summarize_debug_log.py",
    "mode=quickPaste",
    "mode=learningPreview",
    "make validate-manual-e2e-report",
]

SYNTHETIC_REPORT_REPLACEMENTS = {
    "- Date:": "- Date: 2026-06-01",
    "- Tester:": "- Tester: validator-smoke",
    "- macOS version:": "- macOS version: 14.0",
    "- Hardware:": "- Hardware: validator-smoke",
    "- Target text app:": "- Target text app: TextEdit",
    "- Accessibility trusted: yes/no": "- Accessibility trusted: yes",
    "- Microphone status before run:": "- Microphone status before run: authorized",
    "- Speech recognition status before run:": "- Speech recognition status before run: authorized",
    "- Overall result: pass/fail": "- Overall result: pass",
    "- Blocking failures:": "- Blocking failures: none",
    "- Follow-up issues:": "- Follow-up issues: none",
}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def validate_synthetic_completed_report(template_text: str, report_validator: Path) -> None:
    report_text = template_text
    for old, new in SYNTHETIC_REPORT_REPLACEMENTS.items():
        report_text = report_text.replace(old, new, 1)
    report_text = report_text.replace(": pass/fail/not applicable", ": not applicable")
    report_text = report_text.replace(": pass/fail", ": pass")

    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as report:
        report.write(report_text)
        report_path = Path(report.name)

    try:
        result = subprocess.run(
            [sys.executable, str(report_validator), str(report_path)],
            text=True,
            capture_output=True,
            check=False,
        )
    finally:
        report_path.unlink(missing_ok=True)

    if result.returncode != 0:
        fail(
            "synthetic manual E2E report did not validate:\n"
            + result.stdout
            + result.stderr
        )


def validate_report_creator_smoke(template_text: str) -> None:
    with tempfile.TemporaryDirectory() as temporary_directory:
        temporary_root = Path(temporary_directory)
        template_path = temporary_root / "test" / "e2e" / "manual-macos-mvp-report-template.md"
        template_path.parent.mkdir(parents=True)
        template_path.write_text(template_text)

        result = subprocess.run(
            [
                sys.executable,
                str(REPORT_CREATOR.resolve()),
                str(temporary_root),
                "validator-smoke",
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            fail(
                "manual E2E report creator smoke failed:\n"
                + result.stdout
                + result.stderr
            )

        report_path = Path(result.stdout.strip())
        if not report_path.exists():
            fail(f"manual E2E report creator did not create report: {report_path}")
        report_text = report_path.read_text()
        if "- Date:" not in report_text or "validator-smoke" not in report_path.name:
            fail("manual E2E report creator output is missing date or expected slug")


def validate_log_summarizer_smoke() -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".log", delete=False) as log:
        log.write(
            "2026-06-01T00:00:00Z recordVoiceInput completed; "
            "transcriptLength=10 correctedLength=20; mode=quickPaste\n"
        )
        log.write(
            "2026-06-01T00:01:00Z recordVoiceInput completed; "
            "transcriptLength=10 correctedLength=20; mode=learningPreview\n"
        )
        log_path = Path(log.name)

    try:
        result = subprocess.run(
            [sys.executable, str(LOG_SUMMARIZER), str(log_path)],
            text=True,
            capture_output=True,
            check=False,
        )
    finally:
        log_path.unlink(missing_ok=True)

    if result.returncode != 0:
        fail("debug log summarizer smoke failed:\n" + result.stdout + result.stderr)
    for snippet in ["mode=quickPaste: 1", "mode=learningPreview: 1"]:
        if snippet not in result.stdout:
            fail("debug log summarizer smoke missing output: " + snippet)


def validate_debug_launcher_smoke() -> None:
    text = DEBUG_LAUNCHER.read_text()
    required = [
        '["open", "-n", str(APP), "--args", "--debug"]',
        "summarize_debug_log.py",
        "debug.log",
    ]
    missing = [snippet for snippet in required if snippet not in text]
    if missing:
        fail("manual E2E debug launcher missing snippets: " + ", ".join(missing))


def main() -> None:
    if not CHECKLIST.exists():
        fail(f"missing manual E2E checklist: {CHECKLIST}")
    if not REPORT_TEMPLATE.exists():
        fail(f"missing manual E2E report template: {REPORT_TEMPLATE}")
    if not REPORT_CREATOR.exists():
        fail(f"missing manual E2E report creator: {REPORT_CREATOR}")
    if not LOG_SUMMARIZER.exists():
        fail(f"missing debug log summarizer: {LOG_SUMMARIZER}")
    if not DEBUG_LAUNCHER.exists():
        fail(f"missing manual E2E debug launcher: {DEBUG_LAUNCHER}")
    if not README.exists():
        fail(f"missing manual E2E README: {README}")
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

    validate_report_creator_smoke(report_text)
    validate_synthetic_completed_report(report_text, report_validator)
    validate_log_summarizer_smoke()
    validate_debug_launcher_smoke()

    readme_text = README.read_text()
    missing_readme = [
        snippet for snippet in REQUIRED_README_SNIPPETS
        if snippet not in readme_text
    ]
    if missing_readme:
        fail("manual E2E README missing snippets: " + ", ".join(missing_readme))

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

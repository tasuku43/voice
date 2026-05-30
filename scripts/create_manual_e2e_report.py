#!/usr/bin/env python3
from datetime import datetime
from pathlib import Path
import re
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
TEMPLATE = ROOT / "test" / "e2e" / "manual-macos-mvp-report-template.md"
REPORT_DIR = ROOT / "test" / "e2e" / "reports"


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def slug(value: str) -> str:
    lowered = value.lower().strip()
    normalized = re.sub(r"[^a-z0-9]+", "-", lowered)
    return normalized.strip("-") or "manual-macos-mvp"


def main() -> None:
    if not TEMPLATE.exists():
        fail(f"missing report template: {TEMPLATE}")

    run_id = sys.argv[2] if len(sys.argv) > 2 else datetime.now().strftime("%Y%m%d-%H%M%S")
    report_path = REPORT_DIR / f"{slug(run_id)}.md"
    if report_path.exists():
        fail(f"report already exists: {report_path}")

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    text = TEMPLATE.read_text()
    today = datetime.now().strftime("%Y-%m-%d")
    text = text.replace("- Date:", f"- Date: {today}", 1)
    report_path.write_text(text)
    print(report_path)


if __name__ == "__main__":
    main()

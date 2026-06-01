#!/usr/bin/env python3
from pathlib import Path
import sys


DEFAULT_LOG = (
    Path.home()
    / "Library"
    / "Logs"
    / "VoiceAgentInput"
    / "debug.log"
)

MODE_MARKERS = [
    "mode=quickPaste",
    "mode=learningPreview",
]


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    log_path = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else DEFAULT_LOG
    if not log_path.exists():
        fail(f"missing debug log: {log_path}")

    text = log_path.read_text(errors="replace")
    print(f"Debug log: {log_path}")
    for marker in MODE_MARKERS:
        lines = [line for line in text.splitlines() if marker in line]
        print(f"{marker}: {len(lines)}")
        if lines:
            print(f"  last: {lines[-1]}")

    missing = [marker for marker in MODE_MARKERS if marker not in text]
    if missing:
        fail("debug log missing mode markers: " + ", ".join(missing))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
from pathlib import Path
import os
import sys


FORBIDDEN_SUFFIXES = {
    ".aac",
    ".aif",
    ".aiff",
    ".caf",
    ".m4a",
    ".mp3",
    ".wav",
}

FORBIDDEN_NAME_MARKERS = [
    "audio",
    "raw-audio",
    "raw_audio",
    "raw-transcript",
    "raw_transcript",
    "transcript",
]

FORBIDDEN_LOG_MARKERS = [
    " rawTranscript=",
    " transcript=",
    " speech snapshot final=",
]


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def home_directory() -> Path:
    return Path(os.environ.get("HOME", str(Path.home()))).expanduser()


def relative(path: Path, base: Path) -> str:
    try:
        return str(path.relative_to(base))
    except ValueError:
        return str(path)


def app_support_directory(home: Path) -> Path:
    return home / "Library" / "Application Support" / "VoiceAgentInput"


def debug_log_path(home: Path) -> Path:
    return home / "Library" / "Logs" / "VoiceAgentInput" / "debug.log"


def inspect_app_support(directory: Path) -> list[Path]:
    if not directory.exists():
        return []

    forbidden: list[Path] = []
    for path in directory.rglob("*"):
        if not path.is_file():
            continue
        lower_name = path.name.lower()
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            forbidden.append(path)
            continue
        if any(marker in lower_name for marker in FORBIDDEN_NAME_MARKERS):
            forbidden.append(path)
    return forbidden


def inspect_debug_log(log_path: Path) -> list[str]:
    if not log_path.exists():
        return []

    matches: list[str] = []
    for line_number, line in enumerate(log_path.read_text(errors="replace").splitlines(), start=1):
        if any(marker in line for marker in FORBIDDEN_LOG_MARKERS):
            matches.append(f"{line_number}: {line}")
    return matches


def main() -> None:
    home = home_directory()
    support = app_support_directory(home)
    log_path = debug_log_path(home)

    forbidden_files = inspect_app_support(support)
    forbidden_log_lines = inspect_debug_log(log_path)

    print(f"application_support={support}")
    print(f"debug_log={log_path}")
    print(f"forbidden_local_files={len(forbidden_files)}")
    for path in forbidden_files:
        print(f"forbidden_local_file={relative(path, support)}")
    print(f"forbidden_debug_log_lines={len(forbidden_log_lines)}")
    for line in forbidden_log_lines:
        print(f"forbidden_debug_log_line={line}")

    if forbidden_files or forbidden_log_lines:
        fail("manual E2E privacy inspection failed")

    print("manual E2E privacy inspection ok")


if __name__ == "__main__":
    main()

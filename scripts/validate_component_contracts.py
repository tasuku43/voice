#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")

CONTRACT_FILES = [
    "audio-capture.md",
    "speech-to-text.md",
    "local-context-model.md",
    "normalization.md",
    "prompt-refinement.md",
    "voice-input-pipeline.md",
    "preview-fallback.md",
    "learning.md",
    "output.md",
]

SESSION_FILES = [
    "audio-capture-session.md",
    "speech-to-text-session.md",
    "local-context-model-session.md",
    "normalization-session.md",
    "prompt-refinement-session.md",
    "repository-vocabulary-session.md",
    "preview-fallback-session.md",
    "learning-session.md",
    "output-session.md",
]

REQUIRED_CONTRACT_SNIPPETS = [
    "## Inputs",
    "## Outputs",
    "## Allowed",
    "## Forbidden",
    "## Read First",
    "## May Touch",
    "## Avoid Touching",
    "## Tests",
    "## Done",
]

REQUIRED_SESSION_SNIPPETS = [
    "Purpose:",
    "Read:",
    "May touch:",
    "Avoid:",
    "Contract:",
    "Tests:",
    "Done:",
]


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def validate_files(directory: Path, names: list[str], snippets: list[str], label: str) -> None:
    missing: list[str] = []
    for name in names:
        path = directory / name
        if not path.exists():
            missing.append(f"{label}: {name}: missing file")
            continue
        text = path.read_text()
        for snippet in snippets:
            if snippet not in text:
                missing.append(f"{label}: {name}: {snippet}")
    if missing:
        fail("component contract validation failed: " + ", ".join(missing))


def main() -> None:
    validate_files(ROOT / "docs" / "contracts", CONTRACT_FILES, REQUIRED_CONTRACT_SNIPPETS, "contract")
    validate_files(ROOT / "docs" / "codex-sessions", SESSION_FILES, REQUIRED_SESSION_SNIPPETS, "session")
    print("component contracts ok")


if __name__ == "__main__":
    main()

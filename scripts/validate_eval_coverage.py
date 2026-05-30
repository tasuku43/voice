#!/usr/bin/env python3
import json
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
EVAL_FILE = ROOT / "evals" / "normalization-cases.json"
MIN_CASES = 6
REQUIRED_EXPECTED_TERMS = {
    "Claude Code",
    "Codex",
    "Cursor",
    "TypeScript",
    "Swift",
    "pnpm",
    "npm",
    "MCP",
    "GitHub",
    "branch",
    "error",
}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not EVAL_FILE.exists():
        fail(f"missing eval file: {EVAL_FILE}")

    cases = json.loads(EVAL_FILE.read_text())
    if len(cases) < MIN_CASES:
        fail(f"expected at least {MIN_CASES} eval cases, got {len(cases)}")

    names = [case.get("name") for case in cases]
    duplicate_names = sorted({name for name in names if names.count(name) > 1})
    if duplicate_names:
        fail("duplicate eval case names: " + ", ".join(duplicate_names))

    covered_terms = set()
    malformed = []
    for case in cases:
        name = case.get("name", "<missing name>")
        raw_transcript = case.get("rawTranscript")
        expected_contains = case.get("expectedContains")
        if not isinstance(raw_transcript, str) or not raw_transcript:
            malformed.append(f"{name}: rawTranscript")
        if not isinstance(expected_contains, list) or not expected_contains:
            malformed.append(f"{name}: expectedContains")
        else:
            covered_terms.update(expected_contains)

    if malformed:
        fail("malformed eval cases: " + ", ".join(malformed))

    missing_terms = sorted(REQUIRED_EXPECTED_TERMS - covered_terms)
    if missing_terms:
        fail("eval coverage missing expected terms: " + ", ".join(missing_terms))

    print("eval coverage ok")


if __name__ == "__main__":
    main()

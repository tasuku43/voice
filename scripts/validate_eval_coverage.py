#!/usr/bin/env python3
import json
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
EVAL_FILE = ROOT / "evals" / "normalization-cases.json"
LEARNING_EVAL_FILE = ROOT / "evals" / "learning-cases.json"
HISTORY_LEARNING_EVAL_FILE = ROOT / "evals" / "history-learning-cases.json"
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
    if not LEARNING_EVAL_FILE.exists():
        fail(f"missing learning eval file: {LEARNING_EVAL_FILE}")
    if not HISTORY_LEARNING_EVAL_FILE.exists():
        fail(f"missing history learning eval file: {HISTORY_LEARNING_EVAL_FILE}")

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

    learning_cases = json.loads(LEARNING_EVAL_FILE.read_text())
    if not isinstance(learning_cases, list) or not learning_cases:
        fail("expected at least one learning eval case")

    learning_names = [case.get("name") for case in learning_cases]
    duplicate_learning_names = sorted({name for name in learning_names if learning_names.count(name) > 1})
    if duplicate_learning_names:
        fail("duplicate learning eval case names: " + ", ".join(duplicate_learning_names))

    malformed_learning = []
    for case in learning_cases:
        name = case.get("name", "<missing name>")
        for field in ["rawTranscript", "finalEditedPrompt", "laterRawTranscript", "scope"]:
            if not isinstance(case.get(field), str) or not case.get(field):
                malformed_learning.append(f"{name}: {field}")
        expected_contains = case.get("expectedContains")
        if not isinstance(expected_contains, list) or not expected_contains:
            malformed_learning.append(f"{name}: expectedContains")

    if malformed_learning:
        fail("malformed learning eval cases: " + ", ".join(malformed_learning))

    if not any(
        case.get("finalEditedPrompt") == "VoiceAgentInput を直して"
        and case.get("laterRawTranscript") == "ボイスエージェントインプットのプレビューを直して"
        and "VoiceAgentInput" in case.get("expectedContains", [])
        and case.get("scope") == "repository"
        for case in learning_cases
    ):
        fail("learning eval coverage missing katakana project identifier repository case")

    history_learning_cases = json.loads(HISTORY_LEARNING_EVAL_FILE.read_text())
    if not isinstance(history_learning_cases, list) or not history_learning_cases:
        fail("expected at least one history learning eval case")

    history_learning_names = [case.get("name") for case in history_learning_cases]
    duplicate_history_learning_names = sorted({
        name for name in history_learning_names
        if history_learning_names.count(name) > 1
    })
    if duplicate_history_learning_names:
        fail("duplicate history learning eval case names: " + ", ".join(duplicate_history_learning_names))

    malformed_history_learning = []
    for case in history_learning_cases:
        name = case.get("name", "<missing name>")
        history_texts = case.get("historyTexts")
        if not isinstance(history_texts, list) or not history_texts or not all(isinstance(text, str) and text for text in history_texts):
            malformed_history_learning.append(f"{name}: historyTexts")
        for field in ["laterRawTranscript", "scope"]:
            if not isinstance(case.get(field), str) or not case.get(field):
                malformed_history_learning.append(f"{name}: {field}")
        expected_contains = case.get("expectedContains")
        if not isinstance(expected_contains, list) or not expected_contains:
            malformed_history_learning.append(f"{name}: expectedContains")

    if malformed_history_learning:
        fail("malformed history learning eval cases: " + ", ".join(malformed_history_learning))

    if not any(
        "ProjectSpecificName" in case.get("expectedContains", [])
        and case.get("laterRawTranscript") == "project specific nameの設定を直して"
        and case.get("scope") == "repository"
        for case in history_learning_cases
    ):
        fail("history learning eval coverage missing repository project identifier case")

    print("eval coverage ok")


if __name__ == "__main__":
    main()

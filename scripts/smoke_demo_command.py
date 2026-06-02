#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
EXECUTABLE = ROOT / ".build" / "debug" / "voice-agent-input-demo"
INPUT_TEXT = "くらのコードでタイプスクリプトエラーを直して"


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not EXECUTABLE.exists():
        fail(f"missing demo executable: {EXECUTABLE}")

    result = subprocess.run(
        [str(EXECUTABLE), INPUT_TEXT],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
        check=False,
    )
    if result.returncode != 0:
        fail("demo command failed:\n" + result.stderr)

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        fail(f"demo command did not emit JSON: {error}")

    normalization = payload.get("normalization") or {}
    corrected = normalization.get("correctedText") or ""
    if payload.get("mode") != "normalize":
        fail("demo command did not run normalize mode")
    for expected in ["Claude Code", "TypeScript", "error"]:
        if expected not in corrected:
            fail(f"demo corrected prompt missing {expected}: {corrected}")
    with tempfile.TemporaryDirectory() as temporary_home:
        codex_directory = Path(temporary_home) / ".codex"
        codex_directory.mkdir(parents=True)
        (codex_directory / "history.jsonl").write_text(
            '{"role":"user","content":"ProjectSpecificName appears in this repository prompt."}\n'
            '{"role":"user","content":"Please preserve ProjectSpecificName when editing docs."}\n',
            encoding="utf-8",
        )
        history_result = subprocess.run(
            [
                str(EXECUTABLE),
                "--mode", "learn-history",
                "--home", temporary_home,
                "--scope", "repository",
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
            check=False,
        )
        if history_result.returncode != 0:
            fail("demo history learning command failed:\n" + history_result.stderr)
        try:
            history_payload = json.loads(history_result.stdout)
        except json.JSONDecodeError as error:
            fail(f"demo history learning command did not emit JSON: {error}")

        history_learning = history_payload.get("historyLearning") or {}
        candidates = history_learning.get("candidates") or []
        if history_payload.get("mode") != "learn-history":
            fail("demo history learning command did not run learn-history mode")
        if not any(
            candidate.get("correctedPhrase") == "ProjectSpecificName"
            and candidate.get("rawPhrase") == "project specific name"
            and candidate.get("suggestedScope") == "repository"
            for candidate in candidates
        ):
            fail("demo history learning command missing ProjectSpecificName candidate")

        normalized_history_result = subprocess.run(
            [
                str(EXECUTABLE),
                "--mode", "learn-history-normalize",
                "--home", temporary_home,
                "--scope", "repository",
                "project specific nameの設定を直して",
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
            check=False,
        )
        if normalized_history_result.returncode != 0:
            fail("demo history learning normalize command failed:\n" + normalized_history_result.stderr)
        normalized_payload = json.loads(normalized_history_result.stdout)
        corrected_after_history = (normalized_payload.get("normalization") or {}).get("correctedText") or ""
        if normalized_payload.get("mode") != "learn-history-normalize":
            fail("demo history learning normalize command did not run learn-history-normalize mode")
        if "ProjectSpecificName" not in corrected_after_history:
            fail("demo history learning normalize command did not apply learned candidate")

    print("demo command smoke ok")


if __name__ == "__main__":
    main()

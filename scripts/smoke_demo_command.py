#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
import sys


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

    preview = payload.get("preview") or {}
    corrected = preview.get("correctedPrompt") or ""
    if payload.get("mode") != "preview":
        fail("demo command did not run preview mode")
    for expected in ["Claude Code", "TypeScript", "error"]:
        if expected not in corrected:
            fail(f"demo corrected prompt missing {expected}: {corrected}")
    if preview.get("requiresExplicitConfirmation") is not True:
        fail("demo preview does not require explicit confirmation")

    print("demo command smoke ok")


if __name__ == "__main__":
    main()

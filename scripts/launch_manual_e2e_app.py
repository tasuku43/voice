#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
APP = ROOT / ".build" / "VoiceAgentInput.app"
LOG = Path.home() / "Library" / "Logs" / "VoiceAgentInput" / "debug.log"


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not APP.exists():
        fail("missing app bundle; run `make check` or `python3 scripts/build_app_bundle.py .` first")

    command = ["open", "-n", str(APP), "--args", "--debug"]
    subprocess.run(command, check=True)

    print("Launched VoiceAgentInput in debug mode.")
    print(f"App: {APP}")
    print(f"Debug log: {LOG}")
    print(f"Tail log: tail -f {LOG!s}")
    print("Summarize modes after Quick Paste and Learning Preview runs:")
    print("  python3 scripts/summarize_debug_log.py")


if __name__ == "__main__":
    main()

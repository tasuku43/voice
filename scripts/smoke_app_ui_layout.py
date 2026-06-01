#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
EXECUTABLE = ROOT / ".build" / "debug" / "voice-agent-input-app"


def main() -> None:
    if not EXECUTABLE.exists():
        print(f"missing app executable: {EXECUTABLE}", file=sys.stderr)
        sys.exit(1)

    result = subprocess.run(
        [str(EXECUTABLE), "--ui-layout-smoke"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=15,
    )
    print(result.stdout, end="")
    if result.returncode != 0:
        sys.exit(result.returncode)


if __name__ == "__main__":
    main()

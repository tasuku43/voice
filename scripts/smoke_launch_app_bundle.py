#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys
import time


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
APP_EXECUTABLE = ROOT / ".build" / "VoiceAgentInput.app" / "Contents" / "MacOS" / "voice-agent-input-app"
SMOKE_SECONDS = 2.0


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not APP_EXECUTABLE.exists():
        fail(f"missing app executable: {APP_EXECUTABLE}")

    process = subprocess.Popen(
        [str(APP_EXECUTABLE)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    try:
        time.sleep(SMOKE_SECONDS)
        if process.poll() is not None:
            stdout, stderr = process.communicate(timeout=1)
            fail(
                "app exited during smoke launch "
                f"with code {process.returncode}\nstdout:\n{stdout}\nstderr:\n{stderr}"
            )
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)

    print("app launch smoke ok")


if __name__ == "__main__":
    main()

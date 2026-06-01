#!/usr/bin/env python3
import plistlib
import shutil
import stat
import subprocess
import sys
from pathlib import Path


REQUIRED_USAGE_KEYS = [
    "NSMicrophoneUsageDescription",
    "NSSpeechRecognitionUsageDescription",
]


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    executable = root / ".build" / "debug" / "voice-agent-input-app"
    info_plist = root / "src" / "VoiceAgentInputApp" / "Info.plist"
    bundle = root / ".build" / "VoiceAgentInput.app"
    contents = bundle / "Contents"
    macos = contents / "MacOS"

    if not executable.exists():
        raise SystemExit(f"missing built executable: {executable}")
    if not info_plist.exists():
        raise SystemExit(f"missing Info.plist: {info_plist}")

    with info_plist.open("rb") as handle:
        plist = plistlib.load(handle)
    missing_keys = [key for key in REQUIRED_USAGE_KEYS if not plist.get(key)]
    if missing_keys:
        raise SystemExit(f"Info.plist missing required usage descriptions: {', '.join(missing_keys)}")
    if plist.get("CFBundleExecutable") != executable.name:
        raise SystemExit("CFBundleExecutable must match the built executable name")

    if bundle.exists():
        shutil.rmtree(bundle)
    macos.mkdir(parents=True)
    shutil.copy2(info_plist, contents / "Info.plist")
    target_executable = macos / executable.name
    shutil.copy2(executable, target_executable)
    target_executable.chmod(target_executable.stat().st_mode | stat.S_IXUSR)

    bundle_identifier = plist.get("CFBundleIdentifier")
    subprocess.run(
        [
            "codesign",
            "--force",
            "--sign",
            "-",
            "--identifier",
            bundle_identifier,
            "--requirements",
            f'=designated => identifier "{bundle_identifier}"',
            str(bundle),
        ],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    print(f"built {bundle}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

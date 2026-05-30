#!/usr/bin/env python3
import os
import subprocess
import sys


def run(args):
    return subprocess.run(args, capture_output=True, text=True)


def main():
    developer_dir = run(["xcode-select", "-p"])
    if developer_dir.returncode != 0:
        print("error: xcode-select is not configured.", file=sys.stderr)
        print("Install Xcode, then run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer", file=sys.stderr)
        return 1

    developer_path = developer_dir.stdout.strip()
    xctest = run(["xcrun", "--find", "xctest"])
    xcodebuild = run(["xcodebuild", "-version"])

    if xctest.returncode == 0 and xcodebuild.returncode == 0:
        return 0

    print("error: XCTest is not available in the active developer directory.", file=sys.stderr)
    print(f"active developer directory: {developer_path}", file=sys.stderr)
    print("", file=sys.stderr)
    print("This project uses XCTest for Swift Package tests.", file=sys.stderr)
    print("Install full Xcode, then select it with:", file=sys.stderr)
    print("  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer", file=sys.stderr)
    print("", file=sys.stderr)
    print("After switching, verify with:", file=sys.stderr)
    print("  xcrun --find xctest", file=sys.stderr)
    print("  xcodebuild -version", file=sys.stderr)

    if os.path.exists("/Applications/Xcode.app"):
        print("", file=sys.stderr)
        print("Xcode.app exists, so switching xcode-select may be enough.", file=sys.stderr)

    return 1


if __name__ == "__main__":
    sys.exit(main())

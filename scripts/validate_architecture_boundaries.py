#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
CORE = ROOT / "src" / "VoiceAgentInputCore"


DOMAIN_FORBIDDEN = [
    "import AppKit",
    "import AVFoundation",
    "import Speech",
    "import ApplicationServices",
    "FileManager",
    "Process(",
    "NSEvent",
    "NSPasteboard",
    "SFSpeech",
    "AVAudio",
    "AXIsProcessTrusted",
]

APP_FORBIDDEN = [
    "import AppKit",
    "import AVFoundation",
    "import Speech",
    "import ApplicationServices",
    "NSPasteboard",
    "NSEvent",
    "AVAudio",
    "SFSpeech",
    "AXIsProcessTrusted",
    "Process(",
]

REQUIRED_INFRA_SNIPPETS = {
    "Infra/AVFoundationAudioRecorder.swift": ["import AVFoundation"],
    "Infra/AppleSpeechEngine.swift": ["import Speech"],
    "Infra/AccessibilityTextInsertionController.swift": ["import AppKit", "import ApplicationServices"],
    "Infra/GitRepositoryContextProvider.swift": ["Process()"],
}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def swift_files(path: Path) -> list[Path]:
    if not path.exists():
        return []
    return [candidate for candidate in path.rglob("*.swift") if candidate.is_file()]


def find_forbidden(files: list[Path], snippets: list[str]) -> list[str]:
    hits: list[str] = []
    for path in files:
        text = path.read_text(errors="ignore")
        for snippet in snippets:
            if snippet in text:
                hits.append(f"{path.relative_to(ROOT)}: {snippet}")
    return hits


def main() -> None:
    domain_hits = find_forbidden(swift_files(CORE / "Domain"), DOMAIN_FORBIDDEN)
    if domain_hits:
        fail("Domain boundary violations: " + ", ".join(domain_hits))

    app_hits = find_forbidden(swift_files(CORE / "App"), APP_FORBIDDEN)
    if app_hits:
        fail("App boundary violations: " + ", ".join(app_hits))

    missing: list[str] = []
    for relative_path, snippets in REQUIRED_INFRA_SNIPPETS.items():
        path = CORE / relative_path
        if not path.exists():
            missing.append(f"{path.relative_to(ROOT)}: missing file")
            continue
        text = path.read_text(errors="ignore")
        for snippet in snippets:
            if snippet not in text:
                missing.append(f"{path.relative_to(ROOT)}: {snippet}")

    if missing:
        fail("Infra adapter contract missing snippets: " + ", ".join(missing))

    print("architecture boundaries ok")


if __name__ == "__main__":
    main()

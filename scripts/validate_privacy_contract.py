#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
SOURCE_ROOTS = [
    ROOT / "src",
]


FORBIDDEN_SOURCE_SNIPPETS = [
    "URLSession",
    "URLRequest",
    "NSURLConnection",
    "NWConnection",
    "NWListener",
    "import Network",
    "CKContainer",
    "CloudKit",
    "http://",
    "https://",
]

REQUIRED_SOURCE_SNIPPETS = {
    "src/VoiceAgentInputCore/Infra/AppleSpeechEngine.swift": [
        "requiresOnDeviceRecognition: Bool = true",
        "request.contextualStrings = recognitionHints.contextualStrings",
        "TemporaryRecordedAudioFileStore",
    ],
    "src/VoiceAgentInputCore/Infra/TemporaryRecordedAudioFileStore.swift": [
        "defer",
        "removeItem",
    ],
    "src/VoiceAgentInputCore/Infra/GitRepositoryContextProvider.swift": [
        'guard executable == "/usr/bin/git"',
        "validateLocalReadOnlyGitArguments",
        '["rev-parse", "--show-toplevel"]',
        '["branch", "--show-current"]',
        '["ls-files"]',
        "disallowedCommand",
    ],
    "src/VoiceAgentInputCore/Infra/AVFoundationAudioRecorder.swift": [
        "temporaryDirectory",
        "removeItem",
    ],
    "src/VoiceAgentInputCore/App/LocalContextModelRepository.swift": [
        "exportModel",
        "deleteLocalContextModel",
    ],
}

REQUIRED_DOC_SNIPPETS = {
    "AGENTS.md": [
        "network-backed STT",
        "network-backed LLM",
        "local Foundation Model adapter",
        "must not introduce network IO",
        "using LLM rewriting as the default hotkey conversion path",
    ],
    "docs/contracts/prompt-refinement.md": [
        "Network IO",
        "Cloud LLM calls",
        "LLM-backed rewriting in the default hotkey path",
        "Foundation Model conversion belongs to an explicit local-only fallback stage",
    ],
    "docs/contracts/voice-input-pipeline.md": [
        "optional local Foundation Model fallback",
        "Network IO",
        "Cloud STT or cloud LLM calls",
        "The normal hotkey path remains local and mostly deterministic",
    ],
    "docs/contracts/local-context-model.md": [
        "The local context model is not an LLM",
        "Accept output only from local Foundation Model adapters; network IO remains forbidden",
        "Cloud STT or cloud LLM calls",
        "The default hotkey path can run without LLM conversion",
    ],
    "docs/18-spec-trim-audit.md": [
        "Network IO is out of scope for STT, model education, and any LLM-style fallback",
        "local Foundation Model adapter",
        "Any requirement that the default hotkey path show a preview before insertion",
        "Any cloud STT, cloud LLM, transcript upload, cloud sync, or team dictionary sharing in the MVP",
    ],
}

ALLOWED_WRITE_SNIPPETS = {
    "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
        ".write(to: url, options: [.atomic])",
    ],
    "src/VoiceAgentInputApp/AppDebugLogger.swift": [
        "enabled = arguments.contains(\"--debug\") || environment[\"VOICE_AGENT_INPUT_DEBUG\"] == \"1\"",
        "guard enabled else",
        ".appendingPathComponent(\"Logs\")",
        ".appendingPathComponent(\"VoiceAgentInput\")",
        ".appendingPathComponent(\"debug.log\")",
        "try line.write(to: logFileURL, atomically: true, encoding: .utf8)",
    ],
    "src/VoiceAgentInputApp/AppUILayoutSmoke.swift": [
        ".appendingPathComponent(\".build\")",
        ".appendingPathComponent(\"ui-layout-smoke\")",
        "try? data.write(to: outputDirectory.appendingPathComponent(\"\\(name).png\"), options: .atomic)",
    ],
    "src/VoiceAgentInputCore/Infra/JSONAppSettingsRepository.swift": [
        "try data.write(to: fileURL, options: [.atomic])",
    ],
    "src/VoiceAgentInputCore/Infra/JSONLocalContextModelRepository.swift": [
        "try data.write(to: fileURL, options: [.atomic])",
    ],
    "src/VoiceAgentInputCore/Infra/TemporaryRecordedAudioFileStore.swift": [
        "try audio.data.write(to: url, options: .atomic)",
    ],
}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def source_files() -> list[Path]:
    files: list[Path] = []
    for root in SOURCE_ROOTS:
        if root.exists():
            files.extend(path for path in root.rglob("*.swift") if path.is_file())
    return files


def main() -> None:
    files = source_files()
    forbidden_hits: list[str] = []
    for path in files:
        text = path.read_text(errors="ignore")
        for snippet in FORBIDDEN_SOURCE_SNIPPETS:
            if snippet in text:
                forbidden_hits.append(f"{path.relative_to(ROOT)}: {snippet}")

    if forbidden_hits:
        fail("privacy contract forbidden snippets: " + ", ".join(forbidden_hits))

    write_hits: list[str] = []
    allowed_write_paths = {ROOT / path for path in ALLOWED_WRITE_SNIPPETS}
    for path in files:
        text = path.read_text(errors="ignore")
        if ".write(to:" in text and path not in allowed_write_paths:
            write_hits.append(str(path.relative_to(ROOT)))

    if write_hits:
        fail("privacy contract unexpected file writes: " + ", ".join(write_hits))

    missing: list[str] = []
    for relative_path, snippets in REQUIRED_SOURCE_SNIPPETS.items():
        path = ROOT / relative_path
        if not path.exists():
            missing.append(f"{relative_path}: missing file")
            continue
        text = path.read_text()
        for snippet in snippets:
            if snippet not in text:
                missing.append(f"{relative_path}: {snippet}")

    for relative_path, snippets in REQUIRED_DOC_SNIPPETS.items():
        path = ROOT / relative_path
        if not path.exists():
            missing.append(f"{relative_path}: missing file")
            continue
        text = path.read_text()
        for snippet in snippets:
            if snippet not in text:
                missing.append(f"{relative_path}: {snippet}")

    for relative_path, snippets in ALLOWED_WRITE_SNIPPETS.items():
        path = ROOT / relative_path
        if not path.exists():
            missing.append(f"{relative_path}: missing file")
            continue
        text = path.read_text()
        for snippet in snippets:
            if snippet not in text:
                missing.append(f"{relative_path}: {snippet}")

    if missing:
        fail("privacy contract missing snippets: " + ", ".join(missing))

    print("privacy contract ok")


if __name__ == "__main__":
    main()

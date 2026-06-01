# Agent context

The visible product discussion established these decisions:

- Target platform is Mac.
- The product should be native rather than Electron/Tauri for the main app.
- The differentiator is environment-adaptive voice input, not a preview-first prompt approval flow.
- The first strong use case is speaking into Codex, Claude Code, Cursor, terminal coding agents, IDEs, Slack, Chatwork, and browser text fields.
- macOS Dictation is not the direct competitor; the app adds a local context model that improves STT hints and deterministic post-STT transforms.
- The product has a model education layer and a voice input app layer.
- The normal hotkey path should be fast, local, and mostly deterministic.
- LLM use means local Foundation Model use only. It belongs mainly in model education and may appear in voice input only as an explicit last-resort fallback.
- The MVP should avoid real-time character-by-character insertion.
- The core should be built before UI polish.

Important product phrase:

> Fully local, environment-adaptive voice input for developers.

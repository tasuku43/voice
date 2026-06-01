# Agent context

The visible product discussion established these decisions:

- Target platform is Mac.
- The product should be native rather than Electron/Tauri for the main app.
- The differentiator is dictionary learning for coding-agent prompt input.
- The first strong use case is speaking into Codex, Claude Code, Cursor, and terminal coding agents.
- macOS Dictation is not the direct competitor; the app adds developer-term correction and prompt normalization after STT.
- The MVP should avoid real-time character-by-character insertion. The current product split is `Quick Paste` for daily stop-to-paste input and `Learning Preview` for preview-before-paste dictionary growth.
- The core should be built before STT or UI polish.

Important product phrase:

> A growing voice input dictionary for coding-agent prompts.

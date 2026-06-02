# Product brief

`voice-agent-input` is a macOS-native, fully local voice input utility for developers. A user invokes it with a hotkey, speaks Japanese or mixed Japanese-English developer text, and receives a corrected transcription at the focused cursor.

The product is not primarily a preview-first prompt tool. Its core is environment-adaptive dictation: it builds a local context model from the user's developer environment, then uses that model to improve STT recognition hints and post-STT text transforms.

## Target users

- Developers who use Codex, Claude Code, Cursor, terminal agents, IDE assistants, Slack, Chatwork, GitHub, and similar work surfaces.
- Developers who speak faster than they type but need accurate technical terms.
- Individuals with project-specific terms, repo names, branch names, product names, and team vocabulary that general dictation misses.

## Why existing approaches are insufficient

macOS Dictation is excellent at general speech-to-text, but it is not specialized for:

- coding-agent terminology,
- repository-specific symbols,
- local agent and chat history,
- Git and GitHub vocabulary,
- user-specific misrecognitions,
- scoped dictionaries and recognition hints for technical projects.

This product adds two cooperating layers:

- a model education layer that reads bounded local sources through adapters and builds a local context model,
- a voice input app layer that records, transcribes, transforms, and inserts text using that model.

LLM use is local-only. A local Foundation Model may help educate the local context model, and may be used as a last-resort conversion stage when deterministic transforms are insufficient. The normal hotkey path should remain fast, local, and mostly rule-based.

# Requirements

## Functional requirements

### Voice input path

- Invoke recording from a configurable macOS global hotkey.
- Support press-and-hold recording from the voice-input hotkey.
- Show a compact recording HUD near the focused input when possible, including connection/listening/quiet state, live input-level feedback, elapsed time, stop control, and release-to-paste guidance.
- Transcribe microphone input.
- Pass local context model recognition hints to STT when the STT adapter supports them.
- Apply built-in developer vocabulary transforms after transcription.
- Apply personal context model transforms after built-in transforms.
- Keep local Foundation Model conversion as an optional last-resort stage, not the default hotkey path.
- Insert the corrected transcript at the focused cursor.
- Fall back to copying the corrected transcript when direct insertion is unavailable.
- Avoid automatic submit or command execution after insertion.

### Model education path

- Build a local context model from bounded learning sources.
- Support learning-source adapters for Codex / Claude Code local sessions.
- Support learning-source adapters for Git repository vocabulary.
- Support future local archive/cache adapters for GitHub, Slack, Chatwork, and similar developer context.
- Extract vocabulary, identifiers, recognition hints, and likely spoken forms from learning sources.
- Store learned context locally.
- Reuse learned context for both STT recognition hints and post-STT transforms.
- Let the user enable, disable, rebuild, export, import, or delete local learned context.
- Keep optional local Foundation Model use inside model education unless explicitly enabled as a conversion fallback.

### Secondary workflows

- Support pasteboard copy fallback when direct paste cannot complete.
- Support dictionary scopes such as global, user, repository, and session.
- Provide import/export for dictionaries and context data.
- Provide a delete-all-local-learning-data path.

## Non-functional requirements

- Local-first operation.
- Fully local operation by default and for MVP.
- Deterministic core behavior.
- Explainable corrections.
- Fast enough for repeated hotkey dictation.
- Testable without microphone or macOS permissions.
- LLM fallback must be local-only and optional.

## Security and privacy requirements

- Do not store raw audio by default.
- Do not upload audio or transcripts.
- Do not make network calls for STT, model education, or LLM fallback in MVP.
- Do not export raw audio or raw transcripts as local learning data.
- Do not auto-submit prompts.
- Treat dangerous command substitutions conservatively.

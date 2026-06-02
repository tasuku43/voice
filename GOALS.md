# GOALS.md

## Ideal state

`voice-agent-input` becomes a small, reliable macOS utility for hotkey voice input that understands a developer's local environment. It learns terminology and context from local sources, improves STT recognition hints and post-STT transforms, and inserts corrected text at the focused cursor.

## Success criteria

- A user can invoke voice input from any macOS app.
- Spoken text is transcribed and inserted at the focused cursor.
- Common developer terms normalize correctly and explainably.
- Local learning sources such as Codex / Claude Code history and Git vocabulary can educate the local context model.
- Learned context is reused as STT recognition hints and post-STT transforms.
- Dictionary scope precedence works: session > repository > user > global.
- The app never uploads audio, transcripts, learned context, or fallback conversion text.
- Any LLM usage is local Foundation Model usage and remains outside the default hotkey path unless explicitly enabled as a fallback.
- The core behavior is covered by unit tests, use-case tests, and fixture-driven evals.

## User workflows

1. Enable local learning sources.
2. Build or refresh the local context model.
3. Press a hotkey in Codex, Claude Code, Cursor, terminal, Slack, Chatwork, or a browser.
4. Speak Japanese or mixed Japanese-English developer text.
5. Receive corrected text at the focused cursor.
6. Reuse learned terms automatically in future dictation.

## Evaluation criteria

- Correctness: corrections are deterministic and traceable.
- Reliability: no automatic sending or unsafe command execution.
- Agent usability: spoken developer text becomes accurate enough for coding agents and work chat.
- Contract stability: output and data models remain test-covered.
- Human usability: focused-cursor insertion is fast and low-friction; if direct paste cannot complete, the app copies text to the pasteboard for manual paste.
- Privacy: local-only by default.

## Quality bar

- `make check` succeeds.
- Tests cover the core dictionary and learning behavior.
- Fixtures include realistic Japanese developer utterances.
- Local context model behavior is covered as both recognition hints and post-STT transforms.
- Architecture boundaries remain clear.
- New adapters can be added without rewriting domain logic.

## Deferred extensions

- Apple SpeechAnalyzer / SpeechTranscriber adapter.
- Local-only WhisperKit fallback.
- Local Foundation Model education and conversion fallback.
- GitHub, Slack, and Chatwork learning-source adapters.
- SQLite persistence.

## Non-goals

- Full IME replacement.
- Meeting recording.
- System audio capture.
- Cloud sync.
- Cloud STT or network LLM calls.
- Team administration.
- Automatic prompt submission.
- Autonomous code execution.

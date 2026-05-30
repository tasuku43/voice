# GOALS.md

## Ideal state

`voice-agent-input` becomes a small, reliable macOS utility for speaking high-quality prompts into coding agents. It learns the user's terminology from edits, extracts project vocabulary from repositories, and safely inserts corrected prompts only after confirmation.

## Success criteria

- A user can invoke voice input from any macOS app.
- The app shows a raw transcript and corrected prompt before insertion.
- Common developer terms normalize correctly and explainably.
- User edits produce dictionary candidates.
- Approved dictionary entries are reused in later prompts.
- Dictionary scope precedence works: session > repository > user > global.
- The app never uploads audio or transcripts.
- The core behavior is covered by unit tests, use-case tests, and fixture-driven evals.

## User workflows

1. Speak a Codex instruction in Japanese or mixed Japanese-English.
2. Review the corrected prompt.
3. Edit it when needed.
4. Paste into Codex, Claude Code, Cursor, terminal, Slack, or a browser.
5. Approve useful dictionary candidates.
6. Reuse learned terms automatically in future prompts.

## Evaluation criteria

- Correctness: corrections are deterministic and traceable.
- Reliability: no automatic sending or unsafe command execution.
- Agent usability: prompts become clearer for coding agents.
- Contract stability: output and data models remain test-covered.
- Human usability: preview is fast and low-friction.
- Privacy: local-only by default.

## Quality bar

- `make check` succeeds.
- Tests cover the core dictionary and learning behavior.
- Fixtures include realistic Japanese developer utterances.
- Architecture boundaries remain clear.
- New adapters can be added without rewriting domain logic.

## Deferred extensions

- Apple SpeechAnalyzer / SpeechTranscriber adapter.
- WhisperKit fallback.
- SwiftUI/AppKit menu bar shell.
- Global hotkey.
- Pasteboard and Accessibility insertion.
- Repository context extraction.
- SQLite persistence.
- Dictionary export/import UI.

## Non-goals

- Full IME replacement.
- Meeting recording.
- System audio capture.
- Cloud sync.
- Team administration.
- Automatic prompt submission.
- Autonomous code execution.

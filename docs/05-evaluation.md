# Evaluation

## Correctness

- Exact dictionary replacements apply when `autoApply` is true.
- Scope precedence is respected.
- Multiple spoken forms can map to one canonical form.
- Corrections include explainability metadata.
- Learned local context improves both STT recognition hints and post-STT transforms.

## Reliability

- Normalization is deterministic.
- Dangerous command substitutions are not auto-applied.
- The app never submits text automatically.
- The default hotkey path does not require network IO.
- LLM-backed conversion is local-only and remains an optional fallback.

## Agent usability

- Output should be clearer for coding agents, work chat, and IDE fields than the raw transcript.
- Developer terms should be canonicalized consistently.
- Repository-specific and history-derived vocabulary should improve dictation without overfitting globally.

## Output contract stability

- Demo CLI JSON shape should be covered by tests before being used by external automation.
- Any intentional contract change should update fixtures and docs.

## Performance

- Normalization should be effectively instantaneous for normal prompt lengths.
- Repository scanning should be bounded by file count, bytes, and timeout.
- Model education can be slower than hotkey input, but hotkey dictation should stay fast enough for repeated use.

## Regression prevention

- Unit tests cover deterministic algorithms.
- E2E tests cover the demo CLI path.
- Fixture-driven normalization eval cases cover realistic utterances.
- Fixture-driven history learning eval cases cover source-derived local context model growth and later rule-based reuse.
- Future evals should cover context-model extraction from each learning source adapter and the recognition hints generated from that model.

## Human usability

Minimum acceptable behavior:

- User presses a hotkey, speaks, and receives corrected text at the focused cursor.
- If direct paste is unavailable, the user receives copied text and clear fallback guidance.
- Local learning sources can be enabled, rebuilt, and cleared without exposing audio or transcripts to the network.

Stretch goals:

- Low-latency recording and transcription.
- Local archive/cache adapters for GitHub, Slack, and Chatwork data.
- Optional preview/edit UI for users who want to inspect fallback output before insertion.

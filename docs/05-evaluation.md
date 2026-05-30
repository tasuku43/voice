# Evaluation

## Correctness

- Exact dictionary replacements apply when `autoApply` is true.
- Scope precedence is respected.
- Multiple spoken forms can map to one canonical form.
- Corrections include explainability metadata.

## Reliability

- Normalization is deterministic.
- Dangerous command substitutions are not auto-applied.
- The app never submits text automatically.

## Agent usability

- Output should be clearer for coding agents than the raw transcript.
- Developer terms should be canonicalized consistently.
- Repository-specific vocabulary should eventually improve prompts without overfitting globally.

## Output contract stability

- Demo CLI JSON shape should be covered by tests before being used by external automation.
- Any intentional contract change should update fixtures and docs.

## Performance

- Normalization should be effectively instantaneous for normal prompt lengths.
- Repository scanning should be bounded by file count, bytes, and timeout.

## Regression prevention

- Unit tests cover deterministic algorithms.
- E2E tests cover the demo CLI path.
- Fixture-driven eval cases cover realistic utterances.

## Human usability

Minimum acceptable behavior:

- User can inspect raw and corrected text before paste.
- User can cancel safely.
- User can reject bad dictionary candidates.

Stretch goals:

- Low-latency recording and transcription.
- Repo-aware suggestions.
- Dictionary review UI.

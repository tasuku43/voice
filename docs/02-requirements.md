# Requirements

## Functional requirements

- Invoke recording from a macOS global hotkey.
- Transcribe microphone input.
- Apply dictionary-based normalization.
- Show raw transcript and corrected prompt.
- Allow editing before insertion.
- Paste only after explicit confirmation.
- Extract correction candidates from user edits.
- Store approved dictionary entries locally.
- Support dictionary scopes: global, user, repository, session.
- Provide import/export for dictionaries.
- Provide a delete-all-local-learning-data path.

## Non-functional requirements

- Local-first operation.
- No cloud dependency in MVP.
- Deterministic core behavior.
- Explainable corrections.
- Fast enough for prompt drafting.
- Testable without microphone or macOS permissions.

## Security and privacy requirements

- Do not store raw audio by default.
- Do not upload audio or transcripts.
- Do not export raw audio or raw transcripts as local learning data.
- Do not auto-submit prompts.
- Treat dangerous command substitutions conservatively.

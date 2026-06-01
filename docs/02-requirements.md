# Requirements

## Functional requirements

- Invoke recording from a macOS global push-to-talk hotkey.
- Show a compact recording status near the focused input when possible.
- Transcribe microphone input.
- Apply dictionary-based normalization.
- Support daily `Quick Paste` mode and quality-building `Learning Preview` mode.
- In `Quick Paste`, insert the corrected prompt directly after the user's stop/release confirmation.
- In `Learning Preview`, show raw transcript and corrected prompt.
- In `Learning Preview`, allow editing before insertion so edits can generate learning candidates.
- Paste only after explicit confirmation, including a key-release stop-to-paste flow.
- Recall recent voice inputs from a local history shortcut and paste the selected prompt.
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
- Store voice input history locally as final pasted prompts only.
- Do not auto-submit prompts.
- Treat dangerous command substitutions conservatively.

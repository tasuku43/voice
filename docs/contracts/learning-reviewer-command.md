# Learning Reviewer Command Contract

The learning reviewer command is optional. It runs only when `Learning Settings...` contains a local executable path.

It is not part of speech recognition, dictionary normalization, prompt refinement, paste, or automatic submission. The app invokes it after preview confirmation to review dictionary candidates generated from the confirmed edit.

## Input

The command receives UTF-8 JSON on stdin:

```json
{
  "candidates": [
    {
      "rawPhrase": "コーデックス",
      "correctedPhrase": "Codex",
      "confidence": 0.62,
      "occurrenceCount": 1,
      "reason": "Likely voice vocabulary match.",
      "suggestedScope": "user",
      "approved": false,
      "rejected": false,
      "dangerous": false,
      "autoApplyAllowed": true
    }
  ],
  "diff": {
    "rawText": "コーデックスで直して",
    "autoCorrectedText": "コーデックスで直して",
    "finalEditedText": "Codex で直して"
  }
}
```

## Output

The command must write UTF-8 JSON on stdout:

```json
{
  "candidates": [
    {
      "rawPhrase": "コーデックス",
      "correctedPhrase": "Codex",
      "confidence": 0.82,
      "occurrenceCount": 1,
      "reason": "Local reviewer confirmed likely voice misrecognition.",
      "suggestedScope": "user",
      "approved": false,
      "rejected": false,
      "dangerous": false,
      "autoApplyAllowed": true
    }
  ]
}
```

## Guardrails

- Keep the command local and trusted.
- Do not upload transcripts or candidates.
- Do not persist raw audio or raw transcripts.
- Do not mark dangerous command substitutions as auto-apply.
- Return candidates with the same `rawPhrase`, `correctedPhrase`, and `suggestedScope` whenever possible.
- Do not inject new candidates. If a reviewer returns a candidate that was not in the app-generated input set, the app treats it as review-only and disables auto-apply.

The app preserves dangerous-substitution and injected-candidate guardrails even if a reviewer returns unsafe values.

The app also enforces a short timeout for reviewer commands. A slow command fails the candidate-review step with a timeout error instead of becoming part of the speech-to-preview latency path. Prompt confirmation falls back to unreviewed candidates if optional review fails.

## Example

Use `scripts/local_learning_reviewer_example.py` as a deterministic local smoke reviewer.

In `Learning Settings...`, set:

```text
Reviewer command: /usr/bin/python3
Arguments:
/path/to/voice/scripts/local_learning_reviewer_example.py
```

# First Codex prompt: build toward the ideal state

You are working in the `voice-agent-input` repository.

Read these files first:

- `AGENTS.md`
- `GOALS.md`
- `README.md`
- `docs/13-test-and-eval-strategy.md`
- `docs/14-architecture.md`
- `docs/06-implementation-plan.md`

Goal for this autonomous run:

Move the project as far as practical toward a usable MVP while preserving the product boundary and layered architecture.

The ideal MVP is a macOS-native menu bar app that:

1. accepts a hotkey-triggered voice input flow,
2. transcribes speech through a replaceable STT adapter,
3. normalizes coding-agent terminology through deterministic dictionaries,
4. shows raw transcript and corrected prompt in a preview panel,
5. lets the user edit before insertion,
6. pastes only after explicit confirmation,
7. extracts dictionary candidates from user edits,
8. stores approved dictionary entries locally,
9. never uploads audio or transcripts.

Current scaffold already contains the core normalization and learning direction. Continue from there.

Implementation priorities:

1. Strengthen the core domain and tests if needed.
2. Add a macOS app shell only if the current environment supports it.
3. If macOS APIs are unavailable, add protocols, mocks, and documented adapter seams instead of blocking.
4. Implement preview-before-paste before real microphone recording.
5. Implement deterministic dictionary learning before semantic rewriting.
6. Keep STT replaceable: Apple Speech first, Whisper optional later.
7. Keep privacy defaults local-only.

Required constraints:

- Do not introduce cloud services.
- Do not persist raw audio by default.
- Do not auto-submit prompts.
- Do not build a full IME.
- Do not collapse logic into the UI layer.
- Do not auto-apply dangerous command substitutions.

Testing requirements:

- Add or update tests for every behavior change.
- Add eval cases for realistic prompt normalization examples.
- Keep `make check` green.
- If a command cannot run, explain exactly why.

Before finishing, run:

```bash
make check
```

Final response should include:

- implementation summary,
- files changed,
- tests and evals run,
- E2E coverage status,
- architecture changes,
- contract changes,
- known limitations,
- next recommended task.

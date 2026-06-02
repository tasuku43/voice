# First Codex prompt: build toward the ideal state

You are working in the `voice-agent-input` repository.

Read these files first:

- `GOALS.md`
- `README.md`
- `docs/01-product-brief.md`
- `docs/13-test-and-eval-strategy.md`
- `docs/14-architecture.md`
- `docs/06-implementation-plan.md`

Treat `AGENTS.md` as historical guidance if it conflicts with the current product docs.

Goal for this autonomous run:

Move the project as far as practical toward a usable MVP while preserving the product boundary and layered architecture.

The ideal MVP is a macOS-native menu bar app that:

1. accepts a hotkey-triggered voice input flow,
2. transcribes speech through a replaceable STT adapter,
3. builds a local context model from enabled local learning sources,
4. uses that model as STT recognition hints and deterministic post-STT transforms,
5. inserts corrected text at the focused cursor or copies it when direct insertion is unavailable,
6. keeps preview/edit as a direct-paste fallback only,
7. uses local Foundation Model assistance only for model education or explicit fallback conversion,
8. never performs network IO for STT, model education, or LLM fallback,
9. never uploads audio, transcripts, prompts, or learned context.

Current scaffold already contains the core normalization and learning direction. Continue from there.

Implementation priorities:

1. Strengthen the core domain and tests if needed.
2. Add a macOS app shell only if the current environment supports it.
3. If macOS APIs are unavailable, add protocols, mocks, and documented adapter seams instead of blocking.
4. Make hotkey dictation into the focused cursor the primary path.
5. Implement deterministic local context learning before semantic rewriting.
6. Keep STT replaceable: Apple Speech first, local-only Whisper optional later.
7. Keep privacy defaults local-only.

Required constraints:

- Do not introduce cloud services.
- Do not introduce network IO in voice input, model education, or fallback conversion.
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

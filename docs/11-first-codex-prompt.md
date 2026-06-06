# First Codex prompt: build toward the ideal state

You are working in the `voice-agent-input` repository.

Read these files first:

- `GOALS.md`
- `README.md`
- `docs/01-product-brief.md`
- `docs/13-test-and-eval-strategy.md`
- `docs/14-architecture.md`
- `docs/06-implementation-plan.md`

Use the current product docs above as authoritative. `AGENTS.md` is historical context only.

Goal for this autonomous run:

Move the project as far as practical toward a usable MVP while preserving the product boundary and layered architecture.

The ideal MVP is a macOS-native menu bar app that:

1. accepts a hotkey-triggered voice input flow,
2. transcribes speech through a replaceable STT adapter,
3. builds a local context model from enabled local learning sources,
4. uses that model as STT recognition hints and deterministic post-STT transforms,
5. inserts corrected text at the focused cursor or copies it when direct insertion is unavailable,
6. uses pasteboard copy as the direct-paste fallback,
7. uses local Foundation Model assistance only for model education or explicit fallback conversion,
8. never performs network IO for STT, model education, or LLM fallback,
9. never uploads audio, transcripts, prompts, or learned context.

Current implementation already contains the core normalization, model education loop, AppKit menu bar shell, hotkey flow, local Apple Speech adapter, and local data controls. Continue by tightening the product boundary and deleting obsolete surfaces.

Implementation priorities:

1. Keep hotkey dictation into the focused cursor as the primary path.
2. Keep deterministic local context learning before semantic rewriting.
3. Remove preview/edit/approval, mock-only, debug-only, or raw-data hooks that do not support the core path.
4. Keep STT replaceable: Apple Speech first, local-only Whisper optional later.
5. Keep privacy defaults local-only.
6. If macOS APIs are unavailable, preserve protocols, mocks, and documented adapter seams instead of blocking.

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

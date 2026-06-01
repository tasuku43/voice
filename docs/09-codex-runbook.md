# Codex runbook

## First command

```bash
make check
```

## Goal prompt

```bash
make goal
```

Paste the output into Codex for the first autonomous build run.

## Normal workflow

1. Read `GOALS.md`, `README.md`, `docs/01-product-brief.md`, `docs/13-test-and-eval-strategy.md`, and `docs/14-architecture.md`. Treat `AGENTS.md` as historical repository guidance if it conflicts with current product docs.
2. Inspect the current tree.
3. Choose the next smallest useful milestone.
4. Add tests first or alongside code.
5. Run `make check`.
6. Summarize changes and limitations.

## When blocked

- If macOS-only APIs are unavailable, add protocols and mock adapters.
- If microphone permissions cannot be tested, keep recording behind an adapter and test the use-case behavior.
- If UI cannot be launched, test view models and core flows.

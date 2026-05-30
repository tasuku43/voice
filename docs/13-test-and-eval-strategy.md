# Test and eval strategy

## Roles

### Unit tests

Cover deterministic domain behavior:

- dictionary replacement,
- scope precedence,
- correction metadata,
- candidate extraction,
- dangerous command policy.

### Use-case tests

Cover orchestration:

- normalize raw transcript,
- learn from final edited prompt,
- persist approved entries through repository adapters.

### Infra tests

Cover filesystem and adapter behavior:

- JSON load/save,
- missing file handling,
- malformed data errors.

### E2E tests

Cover the real executable path where practical:

- `swift run voice-agent-input-demo ...`
- expected output shape,
- stable correction behavior.
- `make check` also builds `.build/VoiceAgentInput.app` and validates microphone/speech usage descriptions for the bundled macOS shell.

### Evals

Fixture-driven evals live under `evals/`. Each case should include:

- name,
- raw transcript,
- expected corrected output,
- expected correction count or required canonical terms.

### Golden snapshots

Add golden snapshots only once output contracts are stable enough. When golden output changes, the agent must explain whether it is an intentional contract change or a regression.

## Fixture addition process

1. Add a new eval case under `evals/`.
2. Add or update tests that read it.
3. Run `make check`.
4. Document any new product behavior.

## CI guarantees

CI should run the same validation as `make check`.

## Failure triage

A failing test is a regression unless:

- the product contract changed intentionally,
- docs were updated,
- fixtures were updated,
- the final summary explains the reason.

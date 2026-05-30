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
- `scripts/smoke_demo_command.py` verifies the built demo command still emits JSON preview output with expected developer-term normalization.
- expected output shape,
- stable correction behavior.
- `make check` also builds `.build/VoiceAgentInput.app` and validates microphone/speech usage descriptions for the bundled macOS shell.
- `make check` smoke-launches `.build/VoiceAgentInput.app` long enough to catch immediate startup crashes.
- `make check` validates normalization eval coverage for realistic mixed Japanese-English developer terms.
- `make check` validates architecture boundaries: Domain and App stay free of UI/macOS framework dependencies while framework-specific adapters remain in Infra.
- `make check` validates the app source contract for hotkey wiring, on-device Apple Speech, preview-before-paste, candidate approval, local dictionary data controls, and absence of obvious network calls.
- `make check` validates the privacy contract across source files, including absence of direct networking/cloud snippets, on-device Apple Speech default, an allowlist for file writes, temporary audio cleanup hooks, and local learning data controls.
- `make check` validates MVP coverage snippets across source, tests, docs, and manual E2E artifacts so the main success criteria remain represented.
- `make check` validates that the manual macOS MVP checklist covers real permission prompts, speech transcription, Accessibility paste/fallback, recording settings, local learning, repository vocabulary, and privacy expectations.

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

# Internal boundary note

This Swift project uses `src/` for compileable SwiftPM targets. This `internal/` directory exists to document the intended layered boundary for coding agents that expect a conventional `internal` area in developer-tool scaffolds.

Do not place production Swift source here unless the package structure is intentionally changed.

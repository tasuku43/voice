#!/usr/bin/env python3
from pathlib import Path
import sys

required = [
    'README.md',
    'AGENTS.md',
    'GOALS.md',
    'Package.swift',
    'Makefile',
    'docs/11-first-codex-prompt.md',
    'docs/13-test-and-eval-strategy.md',
    'docs/14-architecture.md',
    '.codex/goals/voice-agent-input-full-build.md',
    'evals/normalization-cases.json',
]

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
missing = [p for p in required if not (root / p).exists()]
if missing:
    for p in missing:
        print(f'missing: {p}', file=sys.stderr)
    raise SystemExit(1)
print('required files ok')

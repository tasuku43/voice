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
    'docs/15-mvp-completion-audit.md',
    'docs/16-architecture-refactor-summary.md',
    'docs/contracts/audio-capture.md',
    'docs/contracts/speech-to-text.md',
    'docs/contracts/normalization.md',
    'docs/contracts/prompt-refinement.md',
    'docs/contracts/voice-input-pipeline.md',
    'docs/contracts/preview-and-approval.md',
    'docs/contracts/learning.md',
    'docs/contracts/output.md',
    'docs/codex-sessions/audio-capture-session.md',
    'docs/codex-sessions/speech-to-text-session.md',
    'docs/codex-sessions/normalization-session.md',
    'docs/codex-sessions/prompt-refinement-session.md',
    'docs/codex-sessions/repository-vocabulary-session.md',
    'docs/codex-sessions/preview-ui-session.md',
    'docs/codex-sessions/learning-session.md',
    'docs/codex-sessions/output-session.md',
    'scripts/smoke_demo_command.py',
    'scripts/validate_architecture_refactor.py',
    'scripts/validate_component_contracts.py',
    'scripts/validate_app_ui_split.py',
    'src/VoiceAgentInputCore/App/PromptProcessingPipeline.swift',
    'src/VoiceAgentInputCore/App/PromptTextTransform.swift',
    'src/VoiceAgentInputCore/App/LocalLearningDataDocumentCodec.swift',
    'src/VoiceAgentInputCore/App/AppSettingsUseCase.swift',
    'src/VoiceAgentInputApp/VoiceAgentInputApp.swift',
    'src/VoiceAgentInputApp/PreviewWindowController.swift',
    'src/VoiceAgentInputApp/CandidateApprovalDialogController.swift',
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

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
    'docs/17-learning-goal-audit.md',
    'docs/18-spec-trim-audit.md',
    'docs/contracts/audio-capture.md',
    'docs/contracts/speech-to-text.md',
    'docs/contracts/local-context-model.md',
    'docs/contracts/normalization.md',
    'docs/contracts/voice-input-pipeline.md',
    'docs/contracts/learning.md',
    'docs/contracts/output.md',
    'docs/codex-sessions/audio-capture-session.md',
    'docs/codex-sessions/speech-to-text-session.md',
    'docs/codex-sessions/local-context-model-session.md',
    'docs/codex-sessions/normalization-session.md',
    'docs/codex-sessions/repository-vocabulary-session.md',
    'docs/codex-sessions/learning-session.md',
    'docs/codex-sessions/output-session.md',
    'scripts/smoke_demo_command.py',
    'scripts/smoke_app_ui_layout.py',
    'scripts/launch_manual_e2e_app.py',
    'scripts/summarize_debug_log.py',
    'scripts/validate_architecture_refactor.py',
    'scripts/validate_component_contracts.py',
    'scripts/validate_app_ui_split.py',
    'scripts/validate_learning_goal_audit.py',
    'src/VoiceAgentInputApp/main.swift',
    'src/VoiceAgentInputApp/AppDebugLogger.swift',
    'src/VoiceAgentInputApp/AppLayout.swift',
    'src/VoiceAgentInputApp/AppUILayoutSmoke.swift',
    'src/VoiceAgentInputApp/RecordingFeedbackWindowController.swift',
    'src/VoiceAgentInputCore/App/PromptProcessingPipeline.swift',
    'src/VoiceAgentInputCore/App/PromptTextTransform.swift',
    'src/VoiceAgentInputCore/App/LocalContextModel.swift',
    'src/VoiceAgentInputCore/App/LocalContextModelDocumentCodec.swift',
    'src/VoiceAgentInputCore/App/LocalContextModelRepository.swift',
    'src/VoiceAgentInputCore/App/SpeechRecognitionHints.swift',
    'src/VoiceAgentInputCore/Infra/LocalAppDataStore.swift',
    'src/VoiceAgentInputCore/App/AppSettingsUseCase.swift',
    'src/VoiceAgentInputCore/App/LearningSource.swift',
    'src/VoiceAgentInputCore/App/LearningSourceSelection.swift',
    'src/VoiceAgentInputCore/App/AgentHistoryTextProvider.swift',
    'src/VoiceAgentInputCore/App/AgentHistoryLearningModeUseCase.swift',
    'src/VoiceAgentInputCore/App/LocalContextCandidateGenerationUseCase.swift',
    'src/VoiceAgentInputCore/App/RepositoryVocabularyLearningSource.swift',
    'src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift',
    'src/VoiceAgentInputCore/Infra/JSONLocalContextModelRepository.swift',
    'src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift',
    'src/VoiceAgentInputApp/VoiceAgentInputApp.swift',
    '.codex/goals/voice-agent-input-full-build.md',
    'evals/normalization-cases.json',
    'evals/history-learning-cases.json',
]

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
missing = [p for p in required if not (root / p).exists()]
if missing:
    for p in missing:
        print(f'missing: {p}', file=sys.stderr)
    raise SystemExit(1)
print('required files ok')

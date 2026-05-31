#!/usr/bin/env python3
from pathlib import Path
import sys


ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")


REQUIRED_SNIPPETS = {
    "docs/17-learning-goal-audit.md": [
        "mostly rule-based voice input tool",
        "Learn environment-specific vocabulary from local Codex and Claude history.",
        "structured user text extraction",
        "project identifier candidates",
        "testAgentHistoryLearningApprovalEvolvesRuleBasedNormalizationForProjectTerms",
        "interactiveLearningReviewerTimeoutSeconds",
        "testPromptEditLearningFallsBackToUnreviewedCandidatesWhenReviewerFails",
        "testBundledLocalLearningReviewerExampleFollowsCommandContract",
        "manual evidence still needed",
    ],
    "docs/contracts/learning.md": [
        "Bounded local Codex/Claude history text",
        "Generate dictionary candidates from local agent history after explicit user action.",
        "Reuse deterministic developer-term speech rules across history learning and edit learning.",
        "If candidate review fails, confirmation still returns the prompt and unreviewed candidates",
        "Persist approved entries only after user approval.",
    ],
    "docs/contracts/learning-reviewer-command.md": [
        "The learning reviewer command is optional.",
        "Do not upload transcripts or candidates.",
        "Do not inject new candidates.",
        "short timeout",
        "falls back to unreviewed candidates",
    ],
    "src/VoiceAgentInputCore/Infra/LocalAgentHistoryTextProvider.swift": [
        ".codex/history.jsonl",
        ".claude/projects",
        "maximumBytesPerFile",
        "userTextFragments",
        "parsedStructuredJSON",
        "contentModificationDate",
    ],
    "src/VoiceAgentInputCore/Domain/DeveloperTermSpeechRules.swift": [
        "spokenIdentifierPhrase",
        "identifierComponents",
    ],
    "src/VoiceAgentInputCore/App/PromptEditLearningUseCase.swift": [
        "candidateReviewer.review",
        "reviewedCandidates = confirmed.candidates",
    ],
    "src/VoiceAgentInputApp/VoiceAgentInputApp.swift": [
        "Learn From Agent History...",
        "Learning Settings...",
        "interactiveLearningReviewerTimeoutSeconds",
    ],
    "test/VoiceAgentInputCoreTests/UseCaseAndRepositoryTests.swift": [
        "testLocalAgentHistoryTextProviderExtractsUserTextFromStructuredJSONL",
        "testLocalAgentHistoryTextProviderSkipsStructuredJSONWithoutUserText",
        "testLocalAgentHistoryTextProviderPrefersRecentlyModifiedClaudeProjectFiles",
        "testAgentHistoryLearningApprovalEvolvesRuleBasedNormalizationForProjectTerms",
        "testPromptEditLearningFallsBackToUnreviewedCandidatesWhenReviewerFails",
        "testBundledLocalLearningReviewerExampleFollowsCommandContract",
        "testLocalCommandLearningCandidateReviewerDoesNotAutoApplyInjectedCandidates",
    ],
    "test/VoiceAgentInputCoreTests/CandidateExtractorTests.swift": [
        "testCandidateExtractionInfersProjectIdentifierSpeechRulesFromEditedPrompt",
        "testCandidateExtractorCanUseReplaceableMisrecognitionDetector",
    ],
    "test/e2e/manual-macos-mvp-checklist.md": [
        "Learn From Agent History...",
        "bounded local Codex/Claude history scanning",
        "history-derived project identifier",
    ],
}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    for relative_path, snippets in REQUIRED_SNIPPETS.items():
        path = ROOT / relative_path
        if not path.exists():
            fail(f"missing learning-goal audit file: {relative_path}")
        text = path.read_text()
        missing = [snippet for snippet in snippets if snippet not in text]
        if missing:
            fail(f"{relative_path} missing snippets: {', '.join(missing)}")
    print("learning goal audit ok")


if __name__ == "__main__":
    main()

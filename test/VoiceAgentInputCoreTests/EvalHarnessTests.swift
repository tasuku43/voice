import Foundation
import XCTest
@testable import VoiceAgentInputCore

private struct EvalCase: Decodable {
    var name: String
    var rawTranscript: String
    var expectedContains: [String]
}

private struct LearningEvalCase: Decodable {
    var name: String
    var rawTranscript: String
    var finalEditedPrompt: String
    var laterRawTranscript: String
    var expectedContains: [String]
    var scope: DictionaryScope
}

private struct HistoryLearningEvalCase: Decodable {
    var name: String
    var historyTexts: [String]
    var laterRawTranscript: String
    var expectedContains: [String]
    var scope: DictionaryScope
}

final class EvalHarnessTests: XCTestCase {
    func testNormalizationEvalCases() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = root.appendingPathComponent("evals/normalization-cases.json")
        let data = try Data(contentsOf: url)
        let cases = try JSONDecoder().decode([EvalCase].self, from: data)
        let useCase = PromptNormalizationUseCase(entries: SeedDictionaries.codingAgentEntries)

        for evalCase in cases {
            let result = useCase.normalize(rawText: evalCase.rawTranscript)
            for expected in evalCase.expectedContains {
                XCTAssertTrue(
                    result.correctedText.contains(expected),
                    "Eval case '\(evalCase.name)' expected corrected text to contain '\(expected)', got '\(result.correctedText)'"
                )
            }
        }
    }

    func testLearningEvalCases() async throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = root.appendingPathComponent("evals/learning-cases.json")
        let data = try Data(contentsOf: url)
        let cases = try JSONDecoder().decode([LearningEvalCase].self, from: data)

        for evalCase in cases {
            let previewUseCase = PromptPreviewUseCase(entries: [])
            let preview = previewUseCase.preview(rawTranscript: evalCase.rawTranscript)
            let confirmed = try await PromptEditLearningUseCase(
                previewUseCase: previewUseCase
            ).confirm(
                preview: preview,
                finalEditedPrompt: evalCase.finalEditedPrompt,
                suggestedScope: evalCase.scope
            )
            let learnedEntries = confirmed.candidates
                .map { candidate in
                    var approved = candidate
                    approved.approved = true
                    return approved
                }
                .map { candidate in
                    DictionaryEntry(
                        spokenForms: [candidate.rawPhrase],
                        canonical: candidate.correctedPhrase,
                        kind: .projectTerm,
                        scope: candidate.suggestedScope,
                        confidence: candidate.confidence,
                        autoApply: candidate.autoApplyAllowed
                    )
                }
            let result = PromptNormalizationUseCase(entries: learnedEntries)
                .normalize(rawText: evalCase.laterRawTranscript)

            for expected in evalCase.expectedContains {
                XCTAssertTrue(
                    result.correctedText.contains(expected),
                    "Learning eval case '\(evalCase.name)' expected corrected text to contain '\(expected)', got '\(result.correctedText)'"
                )
            }
        }
    }

    func testHistoryLearningEvalCases() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = root.appendingPathComponent("evals/history-learning-cases.json")
        let data = try Data(contentsOf: url)
        let cases = try JSONDecoder().decode([HistoryLearningEvalCase].self, from: data)

        for evalCase in cases {
            let result = try AgentHistoryLearningModeUseCase(
                historyProvider: EvalAgentHistoryTextProvider(texts: evalCase.historyTexts),
                dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
            ).generateCandidates(scope: evalCase.scope)
            let learnedEntries = result.candidates.map { candidate in
                DictionaryEntry(
                    spokenForms: [candidate.rawPhrase],
                    canonical: candidate.correctedPhrase,
                    kind: .projectTerm,
                    scope: candidate.suggestedScope,
                    confidence: candidate.confidence,
                    autoApply: candidate.autoApplyAllowed
                )
            }
            let normalized = PromptNormalizationUseCase(entries: learnedEntries)
                .normalize(rawText: evalCase.laterRawTranscript)

            for expected in evalCase.expectedContains {
                XCTAssertTrue(
                    normalized.correctedText.contains(expected),
                    "History learning eval case '\(evalCase.name)' expected corrected text to contain '\(expected)', got '\(normalized.correctedText)'"
                )
            }
        }
    }
}

private struct EvalAgentHistoryTextProvider: AgentHistoryTextProvider {
    var texts: [String]

    func historyTexts() throws -> [String] {
        texts
    }
}

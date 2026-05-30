import Foundation
import XCTest
@testable import VoiceAgentInputCore

private struct EvalCase: Decodable {
    var name: String
    var rawTranscript: String
    var expectedContains: [String]
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
}

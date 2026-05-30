import XCTest
@testable import VoiceAgentInputCore

final class CandidateExtractorTests: XCTestCase {
    func testSimpleCandidateExtractionFromEditedPromptPair() {
        let diff = PromptDiff(
            rawText: "くらのコードでタイプスクリプトエラーを直して",
            autoCorrectedText: "くらのコードでタイプスクリプトエラーを直して",
            finalEditedText: "Claude Code で TypeScript error を直して"
        )
        let candidates = CandidateExtractor().extract(from: diff)
        XCTAssertTrue(candidates.contains { $0.rawPhrase == "くらのコード" && $0.correctedPhrase == "Claude Code" })
        XCTAssertTrue(candidates.contains { $0.rawPhrase == "タイプスクリプト" && $0.correctedPhrase == "TypeScript" })
        XCTAssertTrue(candidates.contains { $0.rawPhrase == "エラー" && $0.correctedPhrase == "error" })
        XCTAssertTrue(candidates.allSatisfy { !$0.reason.isEmpty })
    }

    func testDangerousCommandCandidatesAreNotAutoApplied() {
        let diff = PromptDiff(
            rawText: "アールエムを使って消して",
            autoCorrectedText: "アールエムを使って消して",
            finalEditedText: "rm を使って消して"
        )
        let candidates = CandidateExtractor().extract(from: diff)
        let rm = candidates.first { $0.correctedPhrase == "rm" }
        XCTAssertNotNil(rm)
        XCTAssertEqual(rm?.dangerous, true)
        XCTAssertEqual(rm?.autoApplyAllowed, false)
    }
}

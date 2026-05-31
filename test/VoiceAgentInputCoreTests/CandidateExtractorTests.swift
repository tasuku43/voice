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
        let claudeCode = candidates.first { $0.rawPhrase == "くらのコード" && $0.correctedPhrase == "Claude Code" }
        XCTAssertNotNil(claudeCode)
        XCTAssertTrue(claudeCode?.reason.contains("Likely voice misrecognition") == true)
        XCTAssertEqual(claudeCode?.confidence, 0.76)
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

    func testCandidateExtractionInfersDeveloperTermSpeechRulesFromEditedPrompt() {
        let diff = PromptDiff(
            rawText: "すいふとゆーあいでじぇいそんを表示して",
            autoCorrectedText: "すいふとゆーあいでじぇいそんを表示して",
            finalEditedText: "SwiftUI で JSON を表示して"
        )

        let candidates = CandidateExtractor(hints: [:]).extract(from: diff)

        XCTAssertTrue(candidates.contains {
            $0.rawPhrase == "すいふとゆーあい" &&
                $0.correctedPhrase == "SwiftUI"
        })
        XCTAssertTrue(candidates.contains {
            $0.rawPhrase == "じぇいそん" &&
                $0.correctedPhrase == "JSON"
        })
    }

    func testCandidateExtractionInfersProjectIdentifierSpeechRulesFromEditedPrompt() {
        let diff = PromptDiff(
            rawText: "voice agent input のプレビューを直して",
            autoCorrectedText: "voice agent input のプレビューを直して",
            finalEditedText: "VoiceAgentInput のプレビューを直して"
        )

        let candidates = CandidateExtractor(hints: [:]).extract(from: diff)

        XCTAssertTrue(candidates.contains {
            $0.rawPhrase == "voice agent input" &&
                $0.correctedPhrase == "VoiceAgentInput"
        })
    }

    func testCandidateExtractorCanUseReplaceableMisrecognitionDetector() {
        let diff = PromptDiff(
            rawText: "コーデックスで直して",
            autoCorrectedText: "コーデックスで直して",
            finalEditedText: "Codex で直して"
        )
        let candidates = CandidateExtractor(
            misrecognitionDetector: StubVoiceMisrecognitionDetector(
                evidence: VoiceMisrecognitionEvidence(
                    confidence: 0.91,
                    reason: "Stub LLM-style detector reason."
                )
            )
        ).extract(from: diff)

        let codex = candidates.first { $0.correctedPhrase == "Codex" }
        XCTAssertEqual(codex?.confidence, 0.91)
        XCTAssertEqual(codex?.reason, "Stub LLM-style detector reason.")
    }
}

private struct StubVoiceMisrecognitionDetector: VoiceMisrecognitionDetector {
    var evidence: VoiceMisrecognitionEvidence

    func evidence(rawPhrase: String, correctedPhrase: String, diff: PromptDiff) -> VoiceMisrecognitionEvidence {
        evidence
    }
}

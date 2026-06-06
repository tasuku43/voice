import XCTest
@testable import VoiceAgentInputCore

final class NormalizationEngineTests: XCTestCase {
    func testExactDictionaryReplacement() {
        let engine = NormalizationEngine(entries: SeedDictionaries.codingAgentEntries)
        let result = engine.normalize("クロードコードで確認して")
        XCTAssertTrue(result.correctedText.contains("Claude Code"))
        XCTAssertEqual(result.corrections.first?.canonical, "Claude Code")
    }

    func testMultipleSpokenFormsMapToOneCanonical() {
        let engine = NormalizationEngine(entries: SeedDictionaries.codingAgentEntries)
        XCTAssertTrue(engine.normalize("くらのコードで見て").correctedText.contains("Claude Code"))
        XCTAssertTrue(engine.normalize("くらうどこーどで見て").correctedText.contains("Claude Code"))
    }

    func testMixedJapaneseDeveloperTermsDoNotGainExtraSpaces() {
        let entries = [
            DictionaryEntry(
                spokenForms: ["CRIコマンド"],
                canonical: "CLIコマンド",
                kind: .command,
                scope: .user,
                confidence: 1.0,
                autoApply: true
            ),
            DictionaryEntry(
                spokenForms: ["二通り"],
                canonical: "2通り",
                kind: .phrase,
                scope: .user,
                confidence: 1.0,
                autoApply: true
            )
        ]
        let result = NormalizationEngine(entries: entries)
            .normalize("経路CRIコマンドで二通りを確認")

        XCTAssertEqual(result.correctedText, "経路CLIコマンドで2通りを確認")
    }

    func testScopePrecedence() {
        let global = DictionaryEntry(spokenForms: ["ワークスペース"], canonical: "workspace", kind: .projectTerm, scope: .global, confidence: 0.95, autoApply: true)
        let repo = DictionaryEntry(spokenForms: ["ワークスペース"], canonical: "Organization", kind: .symbol, scope: .repository, confidence: 0.80, autoApply: true)
        let engine = NormalizationEngine(entries: [global, repo])
        let result = engine.normalize("ワークスペースを直して")
        XCTAssertTrue(result.correctedText.contains("Organization"))
        XCTAssertFalse(result.correctedText.contains("workspace"))
    }

    func testCorrectionMetadata() {
        let engine = NormalizationEngine(entries: SeedDictionaries.codingAgentEntries)
        let result = engine.normalize("タイプスクリプトエラー")
        XCTAssertGreaterThanOrEqual(result.corrections.count, 2)
        XCTAssertTrue(result.corrections.contains { $0.canonical == "TypeScript" })
        XCTAssertTrue(result.corrections.contains { $0.canonical == "error" })
    }
}

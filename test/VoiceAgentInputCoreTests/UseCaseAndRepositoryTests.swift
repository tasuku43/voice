import Foundation
import XCTest
@testable import VoiceAgentInputCore

final class UseCaseAndRepositoryTests: XCTestCase {
    func testUseCaseNormalizesPrompt() {
        let useCase = PromptNormalizationUseCase(entries: SeedDictionaries.codingAgentEntries)
        let result = useCase.normalize(rawText: "こーでっくすでぴーえぬぴーえむを確認")
        XCTAssertTrue(result.correctedText.contains("Codex"))
        XCTAssertTrue(result.correctedText.contains("pnpm"))
    }

    func testJSONDictionaryRepositoryRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fileURL = directory.appendingPathComponent("dictionary.json")
        let repository = JSONDictionaryRepository(fileURL: fileURL)
        let entries = [DictionaryEntry(spokenForms: ["テスト"], canonical: "test", kind: .command, scope: .user, confidence: 0.9, autoApply: true)]
        try repository.saveEntries(entries)
        let loaded = try repository.loadEntries()
        XCTAssertEqual(loaded, entries)
    }
}

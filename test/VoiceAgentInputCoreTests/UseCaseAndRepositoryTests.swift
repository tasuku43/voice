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

    func testPreviewRequiresExplicitConfirmationBeforeInsertion() {
        let useCase = PromptPreviewUseCase(entries: SeedDictionaries.codingAgentEntries)
        let preview = useCase.preview(rawTranscript: "くらのコードでタイプスクリプトエラーを直して")

        XCTAssertEqual(preview.rawTranscript, "くらのコードでタイプスクリプトエラーを直して")
        XCTAssertTrue(preview.correctedPrompt.contains("Claude Code"))
        XCTAssertTrue(preview.correctedPrompt.contains("TypeScript"))
        XCTAssertTrue(preview.requiresExplicitConfirmation)

        let confirmed = useCase.confirm(preview: preview)
        XCTAssertEqual(confirmed.promptToInsert, preview.correctedPrompt)
        XCTAssertFalse(confirmed.shouldSubmitAutomatically)
    }

    func testVoiceInputFlowTranscribesThroughReplaceableEngineBeforePreview() async throws {
        let speechEngine = MockSpeechEngine()
        let useCase = VoiceInputFlowUseCase(
            speechEngine: speechEngine,
            entries: SeedDictionaries.codingAgentEntries
        )

        let preview = try await useCase.transcribeAndPreview(mockAudioText: "こーでっくすでブランチを確認して")

        XCTAssertEqual(preview.rawTranscript, "こーでっくすでブランチを確認して")
        XCTAssertTrue(preview.correctedPrompt.contains("Codex"))
        XCTAssertTrue(preview.correctedPrompt.contains("branch"))
        XCTAssertTrue(preview.requiresExplicitConfirmation)
    }

    func testConfirmingEditedPromptExtractsLearningCandidates() {
        let useCase = PromptPreviewUseCase(entries: [])
        let preview = useCase.preview(rawTranscript: "くらのコードでタイプスクリプトエラーを直して")
        let confirmed = useCase.confirm(
            preview: preview,
            finalEditedPrompt: "Claude Code で TypeScript error を直して"
        )

        XCTAssertEqual(confirmed.promptToInsert, "Claude Code で TypeScript error を直して")
        XCTAssertTrue(confirmed.candidates.contains { $0.rawPhrase == "くらのコード" && $0.correctedPhrase == "Claude Code" })
        XCTAssertTrue(confirmed.candidates.contains { $0.rawPhrase == "タイプスクリプト" && $0.correctedPhrase == "TypeScript" })
        XCTAssertFalse(confirmed.shouldSubmitAutomatically)
    }

    func testApprovedCandidatesPersistAsLocalDictionaryEntries() throws {
        let repository = InMemoryDictionaryRepository()
        let useCase = DictionaryLearningUseCase(
            repository: repository,
            now: { Date(timeIntervalSince1970: 1_234) }
        )
        let candidates = [
            CorrectionCandidate(rawPhrase: "くらのコード", correctedPhrase: "Claude Code", confidence: 0.72, suggestedScope: .user, autoApplyAllowed: true),
            CorrectionCandidate(rawPhrase: "アールエム", correctedPhrase: "rm", confidence: 0.4, suggestedScope: .user, dangerous: true, autoApplyAllowed: true),
            CorrectionCandidate(rawPhrase: "却下", correctedPhrase: "reject me", confidence: 0.9, suggestedScope: .user, rejected: true, autoApplyAllowed: true)
        ]

        let approved = try useCase.approveCandidates(candidates)
        let saved = try repository.loadEntries()

        XCTAssertEqual(approved.count, 2)
        XCTAssertEqual(saved.count, 2)
        XCTAssertTrue(saved.contains { $0.spokenForms == ["くらのコード"] && $0.canonical == "Claude Code" && $0.autoApply })
        XCTAssertTrue(saved.contains { $0.spokenForms == ["アールエム"] && $0.canonical == "rm" && !$0.autoApply })
        XCTAssertFalse(saved.contains { $0.canonical == "reject me" })
    }

    func testPromptInsertionRequiresExplicitConfirmation() throws {
        let insertionController = MockTextInsertionController()
        let useCase = PromptInsertionUseCase(insertionController: insertionController)
        let confirmed = ConfirmedPrompt(promptToInsert: "Claude Code で確認して", candidates: [])

        XCTAssertThrowsError(try useCase.insert(confirmed, explicitConfirmation: false)) { error in
            XCTAssertEqual(error as? PromptInsertionError, .explicitConfirmationRequired)
        }
        XCTAssertTrue(insertionController.insertedRequests.isEmpty)
    }

    func testPromptInsertionUsesPromptTextWithoutSubmitting() throws {
        let insertionController = MockTextInsertionController()
        let useCase = PromptInsertionUseCase(insertionController: insertionController)
        let confirmed = ConfirmedPrompt(
            promptToInsert: "Claude Code で確認して",
            candidates: [
                CorrectionCandidate(rawPhrase: "くらのコード", correctedPhrase: "Claude Code", confidence: 0.72, suggestedScope: .user, autoApplyAllowed: true)
            ]
        )

        try useCase.insert(confirmed, explicitConfirmation: true)

        XCTAssertEqual(insertionController.insertedRequests, [
            TextInsertionRequest(text: "Claude Code で確認して", submitAutomatically: false)
        ])
    }

    func testPromptInsertionRejectsAutomaticSubmitEvenIfRequestedByCaller() throws {
        let insertionController = MockTextInsertionController()
        let useCase = PromptInsertionUseCase(insertionController: insertionController)
        let confirmed = ConfirmedPrompt(
            promptToInsert: "Claude Code で確認して",
            candidates: [],
            shouldSubmitAutomatically: true
        )

        XCTAssertThrowsError(try useCase.insert(confirmed, explicitConfirmation: true)) { error in
            XCTAssertEqual(error as? PromptInsertionError, .automaticSubmitRejected)
        }
        XCTAssertTrue(insertionController.insertedRequests.isEmpty)
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

private final class InMemoryDictionaryRepository: DictionaryRepository {
    private var entries: [DictionaryEntry]

    init(entries: [DictionaryEntry] = []) {
        self.entries = entries
    }

    func loadEntries() throws -> [DictionaryEntry] {
        entries
    }

    func saveEntries(_ entries: [DictionaryEntry]) throws {
        self.entries = entries
    }
}

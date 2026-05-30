import AppKit
import XCTest
@testable import VoiceAgentInputCore

final class PasteboardInsertionTests: XCTestCase {
    func testPasteboardInsertionWritesPromptTextOnly() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("voice-agent-input-tests-\(UUID().uuidString)"))
        let controller = PasteboardTextInsertionController(pasteboard: pasteboard)

        try controller.insert(TextInsertionRequest(text: "Claude Code で確認して", submitAutomatically: false))

        XCTAssertEqual(pasteboard.string(forType: .string), "Claude Code で確認して")
    }

    func testPromptInsertionUseCaseCanTargetPasteboardAdapter() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("voice-agent-input-tests-\(UUID().uuidString)"))
        let controller = PasteboardTextInsertionController(pasteboard: pasteboard)
        let useCase = PromptInsertionUseCase(insertionController: controller)
        let confirmed = ConfirmedPrompt(promptToInsert: "Codex で branch を確認して", candidates: [])

        try useCase.insert(confirmed, explicitConfirmation: true)

        XCTAssertEqual(pasteboard.string(forType: .string), "Codex で branch を確認して")
    }
}

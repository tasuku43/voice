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
        let confirmed = ConfirmedPrompt(promptToInsert: "Codex で branch を確認して")

        try useCase.insert(confirmed, explicitConfirmation: true)

        XCTAssertEqual(pasteboard.string(forType: .string), "Codex で branch を確認して")
    }

    func testAccessibilityInsertionWritesPasteboardThenSendsPasteCommand() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("voice-agent-input-tests-\(UUID().uuidString)"))
        let pasteCommandSender = MockPasteCommandSender()
        let controller = AccessibilityTextInsertionController(
            pasteboardController: PasteboardTextInsertionController(pasteboard: pasteboard),
            permissionProvider: MockAccessibilityPermissionProvider(status: .trusted),
            pasteCommandSender: pasteCommandSender
        )

        try controller.insert(TextInsertionRequest(text: "Codex で確認して", submitAutomatically: false))

        XCTAssertEqual(pasteboard.string(forType: .string), "Codex で確認して")
        XCTAssertEqual(pasteCommandSender.sendCount, 1)
    }

    func testAccessibilityInsertionRequiresPermissionBeforeWritingPasteboard() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("voice-agent-input-tests-\(UUID().uuidString)"))
        let pasteCommandSender = MockPasteCommandSender()
        let controller = AccessibilityTextInsertionController(
            pasteboardController: PasteboardTextInsertionController(pasteboard: pasteboard),
            permissionProvider: MockAccessibilityPermissionProvider(status: .notTrusted),
            pasteCommandSender: pasteCommandSender
        )

        XCTAssertThrowsError(try controller.insert(TextInsertionRequest(text: "should not write"))) { error in
            XCTAssertEqual(error as? AccessibilityTextInsertionError, .accessibilityPermissionRequired)
        }
        XCTAssertNil(pasteboard.string(forType: .string))
        XCTAssertEqual(pasteCommandSender.sendCount, 0)
    }

    func testAccessibilityInsertionRejectsAutomaticSubmit() throws {
        let pasteCommandSender = MockPasteCommandSender()
        let controller = AccessibilityTextInsertionController(
            permissionProvider: MockAccessibilityPermissionProvider(status: .trusted),
            pasteCommandSender: pasteCommandSender
        )

        XCTAssertThrowsError(try controller.insert(TextInsertionRequest(text: "prompt", submitAutomatically: true))) { error in
            XCTAssertEqual(error as? AccessibilityTextInsertionError, .automaticSubmitRejected)
        }
        XCTAssertEqual(pasteCommandSender.sendCount, 0)
    }
}

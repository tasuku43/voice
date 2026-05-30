import Foundation
import XCTest

final class DemoCLITests: XCTestCase {
    func testDemoPreviewModeUsesRealExecutablePath() throws {
        let output = try runDemo(arguments: [
            "--mode", "preview",
            "くらのコードでタイプスクリプトエラーを直して"
        ])

        XCTAssertEqual(output["mode"] as? String, "preview")
        let preview = try XCTUnwrap(output["preview"] as? [String: Any])
        XCTAssertEqual(preview["rawTranscript"] as? String, "くらのコードでタイプスクリプトエラーを直して")
        XCTAssertTrue((preview["correctedPrompt"] as? String)?.contains("Claude Code") == true)
        XCTAssertEqual(preview["requiresExplicitConfirmation"] as? Bool, true)
        XCTAssertNil(output["confirmed"] as? [String: Any])
    }

    func testDemoConfirmModeNeverSubmitsAutomatically() throws {
        let output = try runDemo(arguments: [
            "--mode", "confirm",
            "--edited", "Claude Code で TypeScript error を直して",
            "くらのコードでタイプスクリプトエラーを直して"
        ])

        XCTAssertEqual(output["mode"] as? String, "confirm")
        let confirmed = try XCTUnwrap(output["confirmed"] as? [String: Any])
        XCTAssertEqual(confirmed["promptToInsert"] as? String, "Claude Code で TypeScript error を直して")
        XCTAssertEqual(confirmed["shouldSubmitAutomatically"] as? Bool, false)
        let candidates = try XCTUnwrap(confirmed["candidates"] as? [[String: Any]])
        XCTAssertTrue(candidates.contains { $0["correctedPhrase"] as? String == "Claude Code" })
        XCTAssertTrue(candidates.contains { $0["correctedPhrase"] as? String == "TypeScript" })
    }

    private func runDemo(arguments: [String]) throws -> [String: Any] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ".build/debug/voice-agent-input-demo")
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorText = String(data: errorData, encoding: .utf8) ?? ""

        XCTAssertEqual(process.terminationStatus, 0, errorText)

        let object = try JSONSerialization.jsonObject(with: outputData)
        return try XCTUnwrap(object as? [String: Any])
    }
}

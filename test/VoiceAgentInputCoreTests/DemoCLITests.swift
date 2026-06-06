import Foundation
import XCTest
import VoiceAgentInputCore

final class DemoCLITests: XCTestCase {
    func testTranscribeCLIHelpUsesRealExecutablePath() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ".build/debug/TranscribeCLI")
        process.arguments = ["--help"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let outputText = String(data: outputData, encoding: .utf8) ?? ""
        let errorText = String(data: errorData, encoding: .utf8) ?? ""

        XCTAssertEqual(process.terminationStatus, 0, errorText)
        XCTAssertTrue(outputText.contains("swift run TranscribeCLI <audio-file>"))
        XCTAssertTrue(outputText.contains("--context contextual-strings.json"))
    }

    func testDemoNormalizeModeUsesRealExecutablePath() throws {
        let output = try runDemo(arguments: [
            "くらのコードでタイプスクリプトエラーを直して"
        ])

        XCTAssertEqual(output["mode"] as? String, "normalize")
        let normalization = try XCTUnwrap(output["normalization"] as? [String: Any])
        XCTAssertEqual(normalization["rawText"] as? String, "くらのコードでタイプスクリプトエラーを直して")
        XCTAssertTrue((normalization["correctedText"] as? String)?.contains("Claude Code") == true)
    }

    func testDemoHistoryLearningModeReadsLocalHistoryWithoutSaving() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let codexDirectory = home.appendingPathComponent(".codex")
        try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
        try """
        {"role":"user","content":"ProjectSpecificName appears in this repository prompt."}
        {"role":"user","content":"Please preserve ProjectSpecificName when editing docs."}
        """.write(to: codexDirectory.appendingPathComponent("history.jsonl"), atomically: true, encoding: .utf8)

        let output = try runDemo(arguments: [
            "--mode", "learn-history",
            "--home", home.path
        ])

        XCTAssertEqual(output["mode"] as? String, "learn-history")
        let historyLearning = try XCTUnwrap(output["historyLearning"] as? [String: Any])
        XCTAssertEqual(historyLearning["scannedTextCount"] as? Int, 1)
        let candidates = try XCTUnwrap(historyLearning["candidates"] as? [[String: Any]])
        let candidate = try XCTUnwrap(candidates.first {
            $0["correctedPhrase"] as? String == "ProjectSpecificName"
        })
        XCTAssertEqual(candidate["rawPhrase"] as? String, "project specific name")
        XCTAssertEqual(candidate["suggestedScope"] as? String, "user")
    }

    func testDemoHistoryLearningNormalizeModeUsesRebuiltModelEntries() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let codexDirectory = home.appendingPathComponent(".codex")
        try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
        try """
        {"role":"user","content":"ProjectSpecificName appears in this repository prompt."}
        {"role":"user","content":"Please preserve ProjectSpecificName when editing docs."}
        """.write(to: codexDirectory.appendingPathComponent("history.jsonl"), atomically: true, encoding: .utf8)

        let output = try runDemo(arguments: [
            "--mode", "learn-history-normalize",
            "--home", home.path,
            "project specific nameの設定を直して"
        ])

        XCTAssertEqual(output["mode"] as? String, "learn-history-normalize")
        let historyLearning = try XCTUnwrap(output["historyLearning"] as? [String: Any])
        XCTAssertEqual((historyLearning["candidates"] as? [[String: Any]])?.count, 1)
        let normalization = try XCTUnwrap(output["normalization"] as? [String: Any])
        XCTAssertEqual(normalization["correctedText"] as? String, "ProjectSpecificName の設定を直して")
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

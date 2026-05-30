import Foundation
import VoiceAgentInputCore

let rawText = CommandLine.arguments.dropFirst().joined(separator: " ").isEmpty
    ? "くらのコードでタイプスクリプトエラーを直して"
    : CommandLine.arguments.dropFirst().joined(separator: " ")

let useCase = PromptNormalizationUseCase(entries: SeedDictionaries.codingAgentEntries)
let result = useCase.normalize(rawText: rawText)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
if let data = try? encoder.encode(result), let json = String(data: data, encoding: .utf8) {
    print(json)
} else {
    print(result.correctedText)
}

import Foundation
import VoiceAgentInputCore

struct DemoOutput: Codable {
    var mode: String
    var preview: PromptPreview?
    var confirmed: ConfirmedPrompt?
    var normalization: NormalizationResult?
}

struct Arguments {
    var mode = "preview"
    var rawText = "くらのコードでタイプスクリプトエラーを直して"
    var editedText: String?
}

func parseArguments(_ rawArguments: [String]) -> Arguments {
    var arguments = Arguments()
    var textParts: [String] = []
    var index = 0

    while index < rawArguments.count {
        let argument = rawArguments[index]
        switch argument {
        case "--mode":
            if index + 1 < rawArguments.count {
                arguments.mode = rawArguments[index + 1]
                index += 2
            } else {
                index += 1
            }
        case "--edited":
            if index + 1 < rawArguments.count {
                arguments.editedText = rawArguments[index + 1]
                index += 2
            } else {
                index += 1
            }
        default:
            textParts.append(argument)
            index += 1
        }
    }

    if !textParts.isEmpty {
        arguments.rawText = textParts.joined(separator: " ")
    }

    return arguments
}

let arguments = parseArguments(Array(CommandLine.arguments.dropFirst()))
let normalizationUseCase = PromptNormalizationUseCase(entries: SeedDictionaries.codingAgentEntries)
let previewUseCase = PromptPreviewUseCase(normalizationUseCase: normalizationUseCase)
let preview = previewUseCase.preview(rawTranscript: arguments.rawText)

let output: DemoOutput
switch arguments.mode {
case "normalize":
    output = DemoOutput(
        mode: "normalize",
        preview: nil,
        confirmed: nil,
        normalization: normalizationUseCase.normalize(rawText: arguments.rawText)
    )
case "confirm":
    output = DemoOutput(
        mode: "confirm",
        preview: preview,
        confirmed: previewUseCase.confirm(preview: preview, finalEditedPrompt: arguments.editedText),
        normalization: nil
    )
default:
    output = DemoOutput(
        mode: "preview",
        preview: preview,
        confirmed: nil,
        normalization: nil
    )
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
let data = try encoder.encode(output)
print(String(data: data, encoding: .utf8) ?? "{}")

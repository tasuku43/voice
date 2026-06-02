import Foundation
import VoiceAgentInputCore

struct DemoOutput: Codable {
    var mode: String
    var preview: PromptPreview?
    var confirmed: ConfirmedPrompt?
    var normalization: NormalizationResult?
    var historyLearning: AgentHistoryLearningModeResult?
}

struct Arguments {
    var mode = "preview"
    var rawText = "くらのコードでタイプスクリプトエラーを直して"
    var editedText: String?
    var homeDirectoryPath: String?
    var scope: DictionaryScope = .user
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
        case "--home":
            if index + 1 < rawArguments.count {
                arguments.homeDirectoryPath = rawArguments[index + 1]
                index += 2
            } else {
                index += 1
            }
        case "--scope":
            if index + 1 < rawArguments.count {
                arguments.scope = DictionaryScope(rawValue: rawArguments[index + 1]) ?? .user
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
        normalization: normalizationUseCase.normalize(rawText: arguments.rawText),
        historyLearning: nil
    )
case "confirm":
    output = DemoOutput(
        mode: "confirm",
        preview: preview,
        confirmed: previewUseCase.confirm(preview: preview, finalEditedPrompt: arguments.editedText),
        normalization: nil,
        historyLearning: nil
    )
case "learn-history":
    let homeDirectory = arguments.homeDirectoryPath.map {
        URL(fileURLWithPath: $0)
    } ?? FileManager.default.homeDirectoryForCurrentUser
    let provider = LocalAgentHistoryTextProvider(homeDirectory: homeDirectory)
    output = DemoOutput(
        mode: "learn-history",
        preview: nil,
        confirmed: nil,
        normalization: nil,
        historyLearning: try AgentHistoryLearningModeUseCase(
            historyProvider: provider
        ).generateCandidates(scope: arguments.scope)
    )
case "learn-history-normalize":
    let homeDirectory = arguments.homeDirectoryPath.map {
        URL(fileURLWithPath: $0)
    } ?? FileManager.default.homeDirectoryForCurrentUser
    let provider = LocalAgentHistoryTextProvider(homeDirectory: homeDirectory)
    let historyLearning = try AgentHistoryLearningModeUseCase(
        historyProvider: provider
    ).generateCandidates(scope: arguments.scope)
    let learnedEntries = historyLearning.candidates.map { candidate in
        DictionaryEntry(
            spokenForms: [candidate.rawPhrase],
            canonical: candidate.correctedPhrase,
            kind: .projectTerm,
            scope: candidate.suggestedScope,
            confidence: candidate.confidence,
            autoApply: candidate.autoApplyAllowed
        )
    }
    output = DemoOutput(
        mode: "learn-history-normalize",
        preview: nil,
        confirmed: nil,
        normalization: PromptNormalizationUseCase(
            entries: SeedDictionaries.codingAgentEntries + learnedEntries
        ).normalize(rawText: arguments.rawText),
        historyLearning: historyLearning
    )
default:
    output = DemoOutput(
        mode: "preview",
        preview: preview,
        confirmed: nil,
        normalization: nil,
        historyLearning: nil
    )
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
let data = try encoder.encode(output)
print(String(data: data, encoding: .utf8) ?? "{}")

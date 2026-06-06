import Foundation
import VoiceAgentInputCore

struct TranscribeCLIArguments {
    var audioPath: String?
    var localeIdentifier = TranscriptionOptions.defaultLocaleIdentifier
    var contextPath: String?
    var outputJSON = false
    var recognitionMode = RecognitionMode.accurate
    var outputDetailLevel = OutputDetailLevel.textOnly
    var help = false
}

enum TranscribeCLIError: Error, CustomStringConvertible {
    case missingAudioPath
    case missingValue(option: String)
    case unknownOption(String)
    case invalidValue(option: String, value: String)

    var description: String {
        switch self {
        case .missingAudioPath:
            return "missing audio file path"
        case let .missingValue(option):
            return "missing value for \(option)"
        case let .unknownOption(option):
            return "unknown option \(option)"
        case let .invalidValue(option, value):
            return "invalid value for \(option): \(value)"
        }
    }
}

@main
struct TranscribeCLI {
    static func main() async {
        do {
            let arguments = try parse(Array(CommandLine.arguments.dropFirst()))
            if arguments.help {
                print(usage)
                return
            }

            guard let audioPath = arguments.audioPath else {
                throw TranscribeCLIError.missingAudioPath
            }

            let contextualStrings = try loadContextualStrings(path: arguments.contextPath)
            let options = TranscriptionOptions(
                locale: Locale(identifier: arguments.localeIdentifier),
                contextualStrings: contextualStrings,
                recognitionMode: arguments.recognitionMode,
                outputDetailLevel: arguments.outputDetailLevel
            )
            let result = try await AppleSpeechEngine(defaultOptions: options)
                .transcribe(audioFile: URL(fileURLWithPath: audioPath), options: options)

            if arguments.outputJSON {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                let data = try encoder.encode(result)
                print(String(data: data, encoding: .utf8) ?? "{}")
            } else {
                print("Text:")
                print(result.text)
                print("")
                print("Locale: \(result.metadata.localeIdentifier)")
                print("Duration: \(result.metadata.durationSeconds.map { String(format: "%.2fs", $0) } ?? "unknown")")
                print("Engine: \(result.metadata.engine)")
                print("Contextual strings: \(result.metadata.contextualStringCount)")
            }
        } catch let error as SpeechEngineError {
            FileHandle.standardError.write(Data((error.userFacingMessage + "\n").utf8))
            FileHandle.standardError.write(Data(("debug: \(error.debugDescription)\n").utf8))
            Foundation.exit(1)
        } catch {
            FileHandle.standardError.write(Data((String(describing: error) + "\n").utf8))
            Foundation.exit(1)
        }
    }

    static func parse(_ rawArguments: [String]) throws -> TranscribeCLIArguments {
        var arguments = TranscribeCLIArguments()
        var index = 0

        while index < rawArguments.count {
            let argument = rawArguments[index]
            switch argument {
            case "--help", "-h":
                arguments.help = true
                index += 1
            case "--locale":
                arguments.localeIdentifier = try value(after: argument, in: rawArguments, at: &index)
            case "--context":
                arguments.contextPath = try value(after: argument, in: rawArguments, at: &index)
            case "--json":
                arguments.outputJSON = true
                index += 1
            case "--mode":
                let value = try value(after: argument, in: rawArguments, at: &index)
                guard let mode = RecognitionMode(rawValue: value) else {
                    throw TranscribeCLIError.invalidValue(option: argument, value: value)
                }
                arguments.recognitionMode = mode
            case "--detail":
                let value = try value(after: argument, in: rawArguments, at: &index)
                guard let detailLevel = OutputDetailLevel(rawValue: value) else {
                    throw TranscribeCLIError.invalidValue(option: argument, value: value)
                }
                arguments.outputDetailLevel = detailLevel
            default:
                if argument.hasPrefix("-") {
                    throw TranscribeCLIError.unknownOption(argument)
                }
                guard arguments.audioPath == nil else {
                    throw TranscribeCLIError.unknownOption(argument)
                }
                arguments.audioPath = argument
                index += 1
            }
        }

        return arguments
    }

    static func value(
        after option: String,
        in rawArguments: [String],
        at index: inout Int
    ) throws -> String {
        guard index + 1 < rawArguments.count else {
            throw TranscribeCLIError.missingValue(option: option)
        }
        let value = rawArguments[index + 1]
        index += 2
        return value
    }

    static func loadContextualStrings(path: String?) throws -> ContextualStringsConfig {
        guard let path else {
            return try loadSavedLocalContextModelHints()
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        if let config = try? JSONDecoder().decode(ContextualStringsConfig.self, from: data) {
            return config
        }

        let rawTaggedStrings = try JSONDecoder().decode([String: [String]].self, from: data)
        var stringsByTag: [ContextualStringsTag: [String]] = [:]
        for (rawTag, strings) in rawTaggedStrings {
            let tag = ContextualStringsTag(rawValue: rawTag) ?? .general
            stringsByTag[tag, default: []].append(contentsOf: strings)
        }
        return ContextualStringsConfig(stringsByTag: stringsByTag)
    }

    static func loadSavedLocalContextModelHints() throws -> ContextualStringsConfig {
        let store = LocalAppDataStore(directoryURL: try LocalAppDataStore.defaultDirectoryURL())
        let repository = try store.localContextModelRepository()
        let entries = try DictionaryEntryLoadingUseCase(
            localContextModelRepository: repository
        ).loadEntries()
        return SpeechRecognitionHintsUseCase()
            .hints(from: entries)
            .contextualStringsConfig
    }

    static var usage: String {
        """
        usage: swift run TranscribeCLI <audio-file> [--locale ja-JP] [--context contextual-strings.json] [--json] [--mode accurate|fast] [--detail textOnly|detailed]

        Context JSON may be either:
          {"commands":["make check"],"technicalTerms":["SpeechAnalyzer"]}
        or an encoded ContextualStringsConfig.
        """
    }
}

import Foundation
import VoiceAgentInputCore

struct TranscribeCLIArguments {
    var audioPath: String?
    var batchPath: String?
    var localeIdentifier = TranscriptionOptions.defaultLocaleIdentifier
    var contextPath: String?
    var expectedPath: String?
    var correctionsPath: String?
    var normalize = false
    var smoothPauses = false
    var foundationModelRefinement = false
    var outputJSON = false
    var recognitionMode = RecognitionMode.accurate
    var outputDetailLevel = OutputDetailLevel.textOnly
    var transcriberProfile = TranscriberProfile.dictation
    var help = false
}

enum TranscribeCLIError: Error, CustomStringConvertible {
    case missingAudioPath
    case noBatchCases(path: String)
    case missingValue(option: String)
    case unknownOption(String)
    case invalidValue(option: String, value: String)

    var description: String {
        switch self {
        case .missingAudioPath:
            return "missing audio file path"
        case let .noBatchCases(path):
            return "no batch cases found under \(path)"
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

            let contextualStrings = try loadContextualStrings(path: arguments.contextPath)
            let options = transcriptionOptions(arguments: arguments, contextualStrings: contextualStrings)
            let engine = AppleSpeechEngine(defaultOptions: options)

            if let batchPath = arguments.batchPath {
                let output = try await runBatch(
                    directoryURL: URL(fileURLWithPath: batchPath),
                    engine: engine,
                    options: options,
                    arguments: arguments
                )
                try printBatchOutput(output, asJSON: arguments.outputJSON)
                return
            }

            guard let audioPath = arguments.audioPath else {
                throw TranscribeCLIError.missingAudioPath
            }

            let textRefiner = try makeTextRefiner(arguments: arguments)
            let output = try await transcribeOutput(
                audioURL: URL(fileURLWithPath: audioPath),
                expectedURL: arguments.expectedPath.map(URL.init(fileURLWithPath:)),
                engine: engine,
                options: options,
                arguments: arguments,
                textRefiner: textRefiner
            )

            if arguments.outputJSON {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                let data: Data
                if output.evaluation != nil || output.normalization != nil {
                    data = try encoder.encode(
                        TranscribeCLIOutput(
                            result: output.result,
                            normalizedText: output.normalizedText,
                            normalization: output.normalization,
                            refinement: output.refinement,
                            evaluation: output.evaluation
                        )
                    )
                } else {
                    data = try encoder.encode(output.result)
                }
                print(String(data: data, encoding: .utf8) ?? "{}")
            } else {
                printSingleOutput(output)
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
            case "--batch":
                arguments.batchPath = try value(after: argument, in: rawArguments, at: &index)
            case "--locale":
                arguments.localeIdentifier = try value(after: argument, in: rawArguments, at: &index)
            case "--context":
                arguments.contextPath = try value(after: argument, in: rawArguments, at: &index)
            case "--expected":
                arguments.expectedPath = try value(after: argument, in: rawArguments, at: &index)
            case "--normalize":
                arguments.normalize = true
                index += 1
            case "--smooth-pauses":
                arguments.smoothPauses = true
                arguments.normalize = true
                index += 1
            case "--foundation-model":
                arguments.foundationModelRefinement = true
                arguments.normalize = true
                index += 1
            case "--corrections":
                arguments.correctionsPath = try value(after: argument, in: rawArguments, at: &index)
                arguments.normalize = true
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
            case "--profile":
                let value = try value(after: argument, in: rawArguments, at: &index)
                guard let profile = TranscriberProfile(rawValue: value) else {
                    throw TranscribeCLIError.invalidValue(option: argument, value: value)
                }
                arguments.transcriberProfile = profile
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

    static func transcriptionOptions(
        arguments: TranscribeCLIArguments,
        contextualStrings: ContextualStringsConfig
    ) -> TranscriptionOptions {
        TranscriptionOptions(
            locale: Locale(identifier: arguments.localeIdentifier),
            contextualStrings: contextualStrings,
            recognitionMode: arguments.recognitionMode,
            outputDetailLevel: arguments.outputDetailLevel,
            transcriberProfile: arguments.transcriberProfile
        )
    }

    static func makeTextRefiner(
        arguments: TranscribeCLIArguments
    ) throws -> (any PromptTextRefiner)? {
        guard arguments.foundationModelRefinement else {
            if arguments.smoothPauses {
                return JapanesePauseSmoothingRefiner()
            }
            return nil
        }
        var refiners: [any PromptTextRefiner] = []
        if arguments.smoothPauses {
            refiners.append(JapanesePauseSmoothingRefiner())
        }
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            refiners.append(FoundationModelPromptTextRefiner())
            return PromptTextRefinerChain(refiners: refiners)
        }
        #endif
        throw TranscribeCLIError.invalidValue(
            option: "--foundation-model",
            value: "FoundationModels requires macOS 26 or later"
        )
    }

    static func transcribeOutput(
        audioURL: URL,
        expectedURL: URL?,
        engine: AppleSpeechEngine,
        options: TranscriptionOptions,
        arguments: TranscribeCLIArguments,
        textRefiner: (any PromptTextRefiner)? = nil
    ) async throws -> TranscribeCLIOutput {
        let result = try await engine.transcribe(audioFile: audioURL, options: options)
        let normalization = try normalize(result.text, arguments: arguments)
        let outputTextBeforeRefinement = normalization?.correctedText ?? result.text
        let refinement = try await textRefiner?.refine(
            PromptTextRefinementRequest(
                transcript: result.transcript,
                normalizedText: outputTextBeforeRefinement
            )
        )
        let outputText = refinement?.refinedText ?? outputTextBeforeRefinement
        let evaluation = try expectedURL.flatMap {
            try loadExpectedText(url: $0).map {
                TranscriptionQualityEvaluation.evaluate(actual: outputText, expected: $0)
            }
        }
        return TranscribeCLIOutput(
            result: result,
            normalizedText: outputTextBeforeRefinement,
            normalization: normalization,
            refinement: refinement,
            evaluation: evaluation
        )
    }

    static func runBatch(
        directoryURL: URL,
        engine: AppleSpeechEngine,
        options: TranscriptionOptions,
        arguments: TranscribeCLIArguments
    ) async throws -> TranscribeCLIBatchOutput {
        let caseURLs = try FileManager.default
            .contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            .filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var cases: [TranscribeCLIBatchCaseOutput] = []
        let textRefiner = try makeTextRefiner(arguments: arguments)

        for caseURL in caseURLs {
            let audioURL = caseURL.appendingPathComponent("audio.wav")
            let expectedURL = caseURL.appendingPathComponent("expected.txt")
            guard FileManager.default.fileExists(atPath: audioURL.path),
                  FileManager.default.fileExists(atPath: expectedURL.path) else {
                continue
            }

            let output = try await transcribeOutput(
                audioURL: audioURL,
                expectedURL: expectedURL,
                engine: engine,
                options: options,
                arguments: arguments,
                textRefiner: textRefiner
            )
            cases.append(TranscribeCLIBatchCaseOutput(
                name: caseURL.lastPathComponent,
                audioPath: audioURL.path,
                expectedPath: expectedURL.path,
                output: output
            ))
        }

        guard !cases.isEmpty else {
            throw TranscribeCLIError.noBatchCases(path: directoryURL.path)
        }
        return TranscribeCLIBatchOutput(
            rootPath: directoryURL.path,
            profile: options.transcriberProfile,
            cases: cases
        )
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

    static func loadExpectedText(path: String?) throws -> String? {
        guard let path else {
            return nil
        }
        return try loadExpectedText(url: URL(fileURLWithPath: path))
    }

    static func loadExpectedText(url: URL) throws -> String? {
        let data = try Data(contentsOf: url)
        return String(data: data, encoding: .utf8)
    }

    static func normalize(
        _ text: String,
        arguments: TranscribeCLIArguments
    ) throws -> NormalizationResult? {
        guard arguments.normalize || arguments.correctionsPath != nil else {
            return nil
        }

        let entries = try DictionaryEntryLoadingUseCase(
            localContextModelRepository: try localContextModelRepository(),
            contextualEntries: loadCorrectionEntries(path: arguments.correctionsPath)
        ).loadEntries()
        return PromptNormalizationUseCase(entries: entries).normalize(rawText: text)
    }

    static func loadCorrectionEntries(path: String?) throws -> [DictionaryEntry] {
        guard let path else {
            return []
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        if let entries = try? JSONDecoder().decode([DictionaryEntry].self, from: data) {
            return entries
        }
        return try JSONDecoder()
            .decode([TranscribeCLICorrectionEntry].self, from: data)
            .map(\.dictionaryEntry)
    }

    static func localContextModelRepository() throws -> any LocalContextModelRepository {
        let store = LocalAppDataStore(directoryURL: try LocalAppDataStore.defaultDirectoryURL())
        return try store.localContextModelRepository()
    }

    static func loadSavedLocalContextModelHints() throws -> ContextualStringsConfig {
        let entries = try DictionaryEntryLoadingUseCase(
            localContextModelRepository: try localContextModelRepository()
        ).loadEntries()
        return SpeechRecognitionHintsUseCase()
            .hints(from: entries)
            .contextualStringsConfig
    }

    static var usage: String {
        """
        usage: swift run TranscribeCLI <audio-file> [--locale ja-JP] [--context contextual-strings.json] [--expected expected.txt] [--normalize] [--smooth-pauses] [--foundation-model] [--corrections corrections.json] [--json] [--mode accurate|fast] [--detail textOnly|detailed] [--profile dictation|transcription]
               swift run TranscribeCLI --batch testdata-directory [--locale ja-JP] [--context contextual-strings.json] [--normalize] [--smooth-pauses] [--foundation-model] [--corrections corrections.json] [--json] [--profile dictation|transcription]

        Context JSON may be either:
          {"commands":["make check"],"technicalTerms":["SpeechAnalyzer"]}
        or an encoded ContextualStringsConfig.

        Corrections JSON may be either an array of DictionaryEntry values or:
          [{"spokenForms":["CRIコマンド"],"canonical":"CLIコマンド"}]
        """
    }

    static func printSingleOutput(_ output: TranscribeCLIOutput) {
        let result = output.result
        print("Text:")
        print(output.refinement?.refinedText ?? output.normalizedText ?? result.text)
        if let normalization = output.normalization {
            print("")
            print("Raw text:")
            print(normalization.rawText)
        }
        print("")
        print("Locale: \(result.metadata.localeIdentifier)")
        print("Duration: \(result.metadata.durationSeconds.map { String(format: "%.2fs", $0) } ?? "unknown")")
        print("Engine: \(result.metadata.engine)")
        print("Profile: \(result.metadata.transcriberProfile.rawValue)")
        print("Contextual strings: \(result.metadata.contextualStringCount)")
        if let normalization = output.normalization {
            print("Corrections: \(normalization.corrections.count)")
        }
        if let refinement = output.refinement {
            print("Refinement: \(refinement.engine)")
        }
        if let evaluation = output.evaluation {
            printEvaluation(evaluation)
        }
    }

    static func printBatchOutput(_ output: TranscribeCLIBatchOutput, asJSON: Bool) throws {
        if asJSON {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(output)
            print(String(data: data, encoding: .utf8) ?? "{}")
            return
        }

        print("case,profile,CER,contentCER,editDistance,contentEditDistance,punctuationDistance,lineBreakDistance,segments")
        for item in output.cases {
            guard let evaluation = item.output.evaluation else {
                continue
            }
            print([
                item.name,
                output.profile.rawValue,
                formatRate(evaluation.characterErrorRate),
                formatRate(evaluation.contentCharacterErrorRate),
                "\(evaluation.editDistance)/\(evaluation.expectedCharacterCount)",
                "\(evaluation.contentEditDistance)/\(evaluation.expectedContentCharacterCount)",
                "\(evaluation.punctuationEditDistance)/\(evaluation.expectedPunctuationCount)",
                "\(evaluation.lineBreakEditDistance)/\(evaluation.expectedLineBreakCount)",
                "\(item.output.result.segments.count)"
            ].joined(separator: ","))
        }

        if let summary = output.summary {
            print("average,\(output.profile.rawValue),\(formatRate(summary.averageCharacterErrorRate)),\(formatRate(summary.averageContentCharacterErrorRate)),,,,,")
        }
    }

    static func printEvaluation(_ evaluation: TranscriptionQualityEvaluation) {
        print("CER: \(formatRate(evaluation.characterErrorRate))")
        print("Edit distance: \(evaluation.editDistance)/\(evaluation.expectedCharacterCount)")
        print("Content CER: \(formatRate(evaluation.contentCharacterErrorRate))")
        print("Content edit distance: \(evaluation.contentEditDistance)/\(evaluation.expectedContentCharacterCount)")
        print("Punctuation distance: \(evaluation.punctuationEditDistance)/\(evaluation.expectedPunctuationCount)")
        print("Line break distance: \(evaluation.lineBreakEditDistance)/\(evaluation.expectedLineBreakCount)")
    }

    static func formatRate(_ value: Double) -> String {
        String(format: "%.4f", value)
    }
}

struct TranscribeCLIOutput: Encodable {
    var result: TranscriptionResult
    var normalizedText: String?
    var normalization: NormalizationResult?
    var refinement: PromptTextRefinementResult?
    var evaluation: TranscriptionQualityEvaluation?
}

struct TranscribeCLIBatchOutput: Encodable {
    var rootPath: String
    var profile: TranscriberProfile
    var cases: [TranscribeCLIBatchCaseOutput]

    var summary: TranscribeCLIBatchSummary? {
        let evaluations = cases.compactMap(\.output.evaluation)
        guard !evaluations.isEmpty else {
            return nil
        }
        let count = Double(evaluations.count)
        return TranscribeCLIBatchSummary(
            caseCount: evaluations.count,
            averageCharacterErrorRate: evaluations.map(\.characterErrorRate).reduce(0, +) / count,
            averageContentCharacterErrorRate: evaluations.map(\.contentCharacterErrorRate).reduce(0, +) / count,
            totalEditDistance: evaluations.map(\.editDistance).reduce(0, +),
            totalExpectedCharacterCount: evaluations.map(\.expectedCharacterCount).reduce(0, +),
            totalContentEditDistance: evaluations.map(\.contentEditDistance).reduce(0, +),
            totalExpectedContentCharacterCount: evaluations.map(\.expectedContentCharacterCount).reduce(0, +)
        )
    }
}

struct TranscribeCLIBatchCaseOutput: Encodable {
    var name: String
    var audioPath: String
    var expectedPath: String
    var output: TranscribeCLIOutput
}

struct TranscribeCLIBatchSummary: Encodable {
    var caseCount: Int
    var averageCharacterErrorRate: Double
    var averageContentCharacterErrorRate: Double
    var totalEditDistance: Int
    var totalExpectedCharacterCount: Int
    var totalContentEditDistance: Int
    var totalExpectedContentCharacterCount: Int
}

struct TranscribeCLICorrectionEntry: Decodable {
    var spokenForms: [String]
    var canonical: String
    var recognitionHints: [String]?
    var kind: DictionaryEntryKind?
    var scope: DictionaryScope?
    var confidence: Double?
    var autoApply: Bool?

    var dictionaryEntry: DictionaryEntry {
        DictionaryEntry(
            spokenForms: spokenForms,
            canonical: canonical,
            recognitionHints: recognitionHints,
            kind: kind ?? .phrase,
            scope: scope ?? .session,
            confidence: confidence ?? 1.0,
            autoApply: autoApply ?? true
        )
    }
}

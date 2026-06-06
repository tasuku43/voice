import AVFoundation
import CoreMedia
import Foundation
import Speech

public final class AppleSpeechEngine: SpeechEngine, SpeechToTextEngine, @unchecked Sendable {
    public static let defaultLocaleIdentifier = TranscriptionOptions.defaultLocaleIdentifier
    public static let engineIdentifier = "SpeechAnalyzer"

    public let temporaryDirectory: URL
    public let defaultOptions: TranscriptionOptions

    public init(
        localeIdentifier: String = AppleSpeechEngine.defaultLocaleIdentifier,
        temporaryDirectory: URL = FileManager.default.temporaryDirectory,
        recognitionHints: SpeechRecognitionHints = SpeechRecognitionHints(),
        recognitionMode: RecognitionMode = .accurate,
        outputDetailLevel: OutputDetailLevel = .textOnly
    ) {
        self.temporaryDirectory = temporaryDirectory
        self.defaultOptions = TranscriptionOptionsBuilder(
            localeIdentifier: localeIdentifier,
            recognitionMode: recognitionMode,
            outputDetailLevel: outputDetailLevel
        )
        .withRecognitionHints(recognitionHints)
        .build()
    }

    public init(
        temporaryDirectory: URL = FileManager.default.temporaryDirectory,
        defaultOptions: TranscriptionOptions
    ) {
        self.temporaryDirectory = temporaryDirectory
        self.defaultOptions = defaultOptions
    }

    public func transcribe(audio: RecordedAudio) async throws -> Transcript {
        try await withRecognitionAudioFile(for: audio) { url in
            try await transcribe(audioFile: url, options: defaultOptions).transcript
        }
    }

    public func transcribe(
        audioFile url: URL,
        options: TranscriptionOptions
    ) async throws -> TranscriptionResult {
        try Task.checkCancellation()
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SpeechEngineError.audioFileMissing(path: url.path)
        }

        do {
            let audioFile = try AVAudioFile(forReading: url)
            let durationSeconds = Self.durationSeconds(for: audioFile)
            try validateDuration(durationSeconds)

            if #available(macOS 26.0, *) {
                return try await transcribeWithSpeechAnalyzer(
                    audioFile: audioFile,
                    options: options,
                    durationSeconds: durationSeconds
                )
            } else {
                throw SpeechEngineError.speechAnalyzerUnavailable(requiredOS: "macOS 26")
            }
        } catch let error as SpeechEngineError {
            throw error
        } catch is CancellationError {
            throw SpeechEngineError.cancelled
        } catch {
            throw SpeechEngineError.unsupportedAudioFile(
                path: url.path,
                debugDescription: String(describing: error)
            )
        }
    }

    func withRecognitionAudioFile<T>(
        for audio: RecordedAudio,
        operation: (URL) async throws -> T
    ) async throws -> T {
        if let url = audio.temporaryFileURL {
            defer {
                if audio.shouldDeleteTemporaryFile {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            return try await operation(url)
        }

        return try await TemporaryRecordedAudioFileStore(
            directoryURL: temporaryDirectory
        ).withRecordedAudioFile(audio) { url in
            try await operation(url)
        }
    }

    private func validateDuration(_ durationSeconds: Double?) throws {
        guard let durationSeconds else {
            return
        }
        guard durationSeconds >= Self.minimumAudioDurationSeconds else {
            throw SpeechEngineError.audioTooShort(
                durationSeconds: durationSeconds,
                minimumDurationSeconds: Self.minimumAudioDurationSeconds
            )
        }
    }

    private static var minimumAudioDurationSeconds: Double {
        0.1
    }

    private static func durationSeconds(for audioFile: AVAudioFile) -> Double? {
        let sampleRate = audioFile.processingFormat.sampleRate
        guard sampleRate > 0 else {
            return nil
        }
        return Double(audioFile.length) / sampleRate
    }
}

@available(macOS 26.0, *)
private extension AppleSpeechEngine {
    func transcribeWithSpeechAnalyzer(
        audioFile: AVAudioFile,
        options: TranscriptionOptions,
        durationSeconds: Double?
    ) async throws -> TranscriptionResult {
        guard SpeechTranscriber.isAvailable else {
            throw SpeechEngineError.speechAnalyzerUnavailable(requiredOS: "macOS 26 with SpeechTranscriber support")
        }

        let requestedLocaleIdentifier = options.locale.identifier
        guard let supportedLocale = await SpeechTranscriber.supportedLocale(equivalentTo: options.locale) else {
            throw SpeechEngineError.unsupportedLocale(localeIdentifier: requestedLocaleIdentifier)
        }

        let transcriber = SpeechTranscriber(
            locale: supportedLocale,
            transcriptionOptions: transcriptionOptions(for: options),
            reportingOptions: reportingOptions(for: options),
            attributeOptions: attributeOptions(for: options)
        )

        let assetStatus = await AssetInventory.status(forModules: [transcriber])
        guard assetStatus == .installed else {
            throw SpeechEngineError.onDeviceAssetMissing(
                localeIdentifier: supportedLocale.identifier,
                status: String(describing: assetStatus)
            )
        }

        let context = SpeechAnalysisContextBuilder()
            .analysisContext(from: options.contextualStrings)
        let analyzer = SpeechAnalyzer(
            modules: [transcriber],
            options: SpeechAnalyzer.Options(priority: .userInitiated, modelRetention: .whileInUse)
        )
        try await analyzer.setContext(context)

        let resultCollector = Task {
            try await SpeechTranscriberResultCollector.collect(
                from: transcriber,
                localeIdentifier: supportedLocale.identifier,
                durationSeconds: durationSeconds,
                options: options
            )
        }

        do {
            let lastSampleTime = try await analyzer.analyzeSequence(from: audioFile)
            if let lastSampleTime {
                try await analyzer.finalizeAndFinish(through: lastSampleTime)
            } else {
                await analyzer.cancelAndFinishNow()
            }
            return try await resultCollector.value
        } catch is CancellationError {
            await analyzer.cancelAndFinishNow()
            resultCollector.cancel()
            throw SpeechEngineError.cancelled
        } catch let error as SpeechEngineError {
            await analyzer.cancelAndFinishNow()
            resultCollector.cancel()
            throw error
        } catch {
            await analyzer.cancelAndFinishNow()
            resultCollector.cancel()
            throw SpeechEngineError.transcriptionFailed(
                userMessage: "Apple Speech could not transcribe the recording.",
                debugDescription: String(describing: error)
            )
        }
    }

    func transcriptionOptions(for options: TranscriptionOptions) -> Set<SpeechTranscriber.TranscriptionOption> {
        []
    }

    func reportingOptions(for options: TranscriptionOptions) -> Set<SpeechTranscriber.ReportingOption> {
        var reportingOptions: Set<SpeechTranscriber.ReportingOption> = []
        if options.recognitionMode == .fast {
            reportingOptions.insert(.fastResults)
        }
        if options.outputDetailLevel == .detailed {
            reportingOptions.insert(.alternativeTranscriptions)
        }
        return reportingOptions
    }

    func attributeOptions(for options: TranscriptionOptions) -> Set<SpeechTranscriber.ResultAttributeOption> {
        guard options.outputDetailLevel == .detailed else {
            return []
        }
        return [.audioTimeRange, .transcriptionConfidence]
    }
}

@available(macOS 26.0, *)
struct SpeechAnalysisContextBuilder: Sendable {
    func analysisContext(from config: ContextualStringsConfig) -> AnalysisContext {
        let context = AnalysisContext()
        var contextualStrings: [AnalysisContext.ContextualStringsTag: [String]] = [:]

        for (tag, strings) in config.stringsByTag {
            let speechTag: AnalysisContext.ContextualStringsTag = tag == .general
                ? .general
                : AnalysisContext.ContextualStringsTag(tag.rawValue)
            contextualStrings[speechTag] = strings
        }

        context.contextualStrings = contextualStrings
        return context
    }
}

@available(macOS 26.0, *)
private struct SpeechTranscriberResultCollector {
    static func collect(
        from transcriber: SpeechTranscriber,
        localeIdentifier: String,
        durationSeconds: Double?,
        options: TranscriptionOptions
    ) async throws -> TranscriptionResult {
        var segments: [TranscriptionSegment] = []
        var alternatives: [TranscriptionAlternative] = []

        for try await result in transcriber.results {
            try Task.checkCancellation()
            let text = Self.plainText(result.text)
            guard !text.isEmpty else {
                continue
            }

            segments.append(
                TranscriptionSegment(
                    text: text,
                    startTimeSeconds: result.range.start.secondsIfValid,
                    durationSeconds: result.range.duration.secondsIfValid,
                    confidence: nil,
                    isFinal: result.isFinal
                )
            )

            for alternative in result.alternatives {
                let alternativeText = Self.plainText(alternative)
                guard !alternativeText.isEmpty, alternativeText != text else {
                    continue
                }
                alternatives.append(TranscriptionAlternative(text: alternativeText))
            }
        }

        let text = segments
            .map(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw SpeechEngineError.emptyResult
        }

        return TranscriptionResult(
            text: text,
            segments: segments,
            alternatives: alternatives,
            metadata: TranscriptionMetadata(
                engine: AppleSpeechEngine.engineIdentifier,
                localeIdentifier: localeIdentifier,
                durationSeconds: durationSeconds,
                confidence: nil,
                contextualStringCount: options.contextualStrings.phraseCount,
                recognitionMode: options.recognitionMode,
                outputDetailLevel: options.outputDetailLevel
            )
        )
    }

    private static func plainText(_ text: AttributedString) -> String {
        String(text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension CMTime {
    var secondsIfValid: Double? {
        guard isValid, !isIndefinite else {
            return nil
        }
        let value = seconds
        guard value.isFinite else {
            return nil
        }
        return value
    }
}

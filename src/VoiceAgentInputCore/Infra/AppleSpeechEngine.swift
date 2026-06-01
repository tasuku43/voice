import Foundation
import Speech

public final class AppleSpeechEngine: SpeechToTextEngine, @unchecked Sendable {
    public let localeIdentifier: String
    public let temporaryDirectory: URL
    public let requiresOnDeviceRecognition: Bool
    public let recognitionHints: SpeechRecognitionHints
    public var recognitionSnapshotHandler: (@Sendable (String, Bool) -> Void)?

    public init(
        localeIdentifier: String = "ja-JP",
        temporaryDirectory: URL = FileManager.default.temporaryDirectory,
        requiresOnDeviceRecognition: Bool = true,
        recognitionHints: SpeechRecognitionHints = SpeechRecognitionHints(),
        recognitionSnapshotHandler: (@Sendable (String, Bool) -> Void)? = nil
    ) {
        self.localeIdentifier = localeIdentifier
        self.temporaryDirectory = temporaryDirectory
        self.requiresOnDeviceRecognition = requiresOnDeviceRecognition
        self.recognitionHints = recognitionHints
        self.recognitionSnapshotHandler = recognitionSnapshotHandler
    }

    public func transcribe(audio: RecordedAudio) async throws -> Transcript {
        try await withRecognitionAudioFile(for: audio) { url in
            let recognizer = try recognizer()
            return try await transcribeFile(at: url, recognizer: recognizer)
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

    private func recognizer() throws -> SFSpeechRecognizer {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) else {
            throw AppleSpeechEngineError.recognizerUnavailable(localeIdentifier: localeIdentifier)
        }
        guard recognizer.isAvailable else {
            throw AppleSpeechEngineError.recognizerUnavailable(localeIdentifier: localeIdentifier)
        }
        return recognizer
    }

    private func transcribeFile(at url: URL, recognizer: SFSpeechRecognizer) async throws -> Transcript {
        try await withCheckedThrowingContinuation { continuation in
            let box = SpeechResultBox(continuation: continuation)
            let request = self.recognitionRequest(url: url)

            recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    let snapshot = result.bestTranscription.formattedString
                    self.recognitionSnapshotHandler?(snapshot, result.isFinal)
                    box.storeLatest(snapshot, localeIdentifier: self.localeIdentifier)
                }

                if let error {
                    let mappedError = AppleSpeechEngineError.map(error)
                    if case .noSpeechDetected = mappedError,
                       box.resumeWithLatestTranscriptIfAvailable(localeIdentifier: self.localeIdentifier) {
                        return
                    }
                    box.resume(throwing: mappedError)
                    return
                }

                guard let result, result.isFinal else {
                    return
                }

                box.resume(returning: box.transcript(
                    preferredFinalText: result.bestTranscription.formattedString,
                    localeIdentifier: self.localeIdentifier
                ))
            }
        }
    }

    public func transcribeMockText(_ text: String) async throws -> String {
        text
    }

    func recognitionRequest(url: URL) -> SFSpeechURLRecognitionRequest {
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = requiresOnDeviceRecognition
        if !recognitionHints.contextualStrings.isEmpty {
            request.contextualStrings = recognitionHints.contextualStrings
        }
        return request
    }
}

public enum AppleSpeechEngineError: Error, Equatable {
    case recognizerUnavailable(localeIdentifier: String)
    case noSpeechDetected
    case transcriptionFailed(description: String)

    static func map(_ error: Error) -> AppleSpeechEngineError {
        let nsError = error as NSError
        if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 1110 {
            return .noSpeechDetected
        }
        return .transcriptionFailed(description: nsError.localizedDescription)
    }
}

private final class SpeechResultBox: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false
    private var accumulator = SpeechTranscriptAccumulator()
    private let continuation: CheckedContinuation<Transcript, Error>

    init(continuation: CheckedContinuation<Transcript, Error>) {
        self.continuation = continuation
    }

    func storeLatest(_ text: String, localeIdentifier: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        lock.lock()
        accumulator.record(trimmed)
        lock.unlock()
    }

    func resumeWithLatestTranscriptIfAvailable(localeIdentifier: String) -> Bool {
        lock.lock()
        let text = accumulator.bestText()
        lock.unlock()

        guard let text else {
            return false
        }
        resume(returning: Transcript(text: text, localeIdentifier: localeIdentifier, confidence: nil))
        return true
    }

    func transcript(preferredFinalText: String, localeIdentifier: String) -> Transcript {
        lock.lock()
        let text = accumulator.bestText(preferredFinalText: preferredFinalText)
            ?? preferredFinalText.trimmingCharacters(in: .whitespacesAndNewlines)
        lock.unlock()

        return Transcript(
            text: text,
            localeIdentifier: localeIdentifier,
            confidence: nil
        )
    }

    func resume(returning transcript: Transcript) {
        guard markResumed() else {
            return
        }
        continuation.resume(returning: transcript)
    }

    func resume(throwing error: Error) {
        guard markResumed() else {
            return
        }
        continuation.resume(throwing: error)
    }

    private func markResumed() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if didResume {
            return false
        }
        didResume = true
        return true
    }
}

struct SpeechTranscriptAccumulator: Sendable {
    private var accumulatedText = ""
    private var latestText = ""

    mutating func record(_ text: String) {
        let normalized = normalizedText(text)
        guard !normalized.isEmpty else {
            return
        }
        latestText = normalized
        accumulatedText = Self.mergedText(accumulatedText, normalized)
    }

    func bestText(preferredFinalText: String? = nil) -> String? {
        let final = preferredFinalText.map(normalizedText) ?? ""
        return Self.mergedText(accumulatedText, final)
            .nilIfEmpty
            ?? accumulatedText.nilIfEmpty
            ?? latestText.nilIfEmpty
    }

    private func normalizedText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func mergedText(_ current: String, _ next: String) -> String {
        guard !current.isEmpty else {
            return next
        }
        guard !next.isEmpty else {
            return current
        }
        if next.contains(current) {
            return next
        }
        if current.contains(next) {
            return current
        }

        if let repaired = repairedFromLastPrefixOccurrence(current, next) {
            return repaired
        }

        let overlap = suffixPrefixOverlap(current, next)
        if overlap > 0 {
            return current + String(next.dropFirst(overlap))
        }

        if let repaired = repairedRollingSnapshotMerge(current, next) {
            return repaired
        }

        return current + joiner(between: current, and: next) + next
    }

    private static func repairedFromLastPrefixOccurrence(_ current: String, _ next: String) -> String? {
        let currentCharacters = Array(current)
        let nextCharacters = Array(next)
        let maximumLength = min(currentCharacters.count, nextCharacters.count)
        guard maximumLength >= minimumRepairOverlapLength else {
            return nil
        }

        for length in stride(from: maximumLength, through: minimumRepairOverlapLength, by: -1) {
            let prefix = nextCharacters.prefix(length)
            let lastStart = lastOccurrence(of: prefix, in: currentCharacters)
            guard let lastStart, lastStart > 0 else {
                continue
            }

            return String(currentCharacters.prefix(lastStart)) + next
        }

        return nil
    }

    private static func lastOccurrence(
        of needle: ArraySlice<Character>,
        in haystack: [Character]
    ) -> Int? {
        guard !needle.isEmpty, haystack.count >= needle.count else {
            return nil
        }

        for start in stride(from: haystack.count - needle.count, through: 0, by: -1) {
            if haystack[start..<start + needle.count].elementsEqual(needle) {
                return start
            }
        }
        return nil
    }

    private static func suffixPrefixOverlap(_ lhs: String, _ rhs: String) -> Int {
        let lhsCharacters = Array(lhs)
        let rhsCharacters = Array(rhs)
        let maximumLength = min(lhsCharacters.count, rhsCharacters.count)
        guard maximumLength > 0 else {
            return 0
        }

        for length in stride(from: maximumLength, through: 1, by: -1) {
            if lhsCharacters.suffix(length).elementsEqual(rhsCharacters.prefix(length)) {
                return length
            }
        }
        return 0
    }

    private static func repairedRollingSnapshotMerge(_ current: String, _ next: String) -> String? {
        let match = longestCommonSubstring(current, next)
        guard match.length >= minimumRepairOverlapLength else {
            return nil
        }

        let currentCharacters = Array(current)
        let nextCharacters = Array(next)
        let currentMatchReachesEnd = match.currentStart + match.length >= currentCharacters.count - 3
        let nextMatchStartsSnapshot = match.nextStart == 0
        guard currentMatchReachesEnd && nextMatchStartsSnapshot else {
            return nil
        }

        let prefix = currentCharacters.prefix(match.currentStart)
        let replacement = nextCharacters.dropFirst(match.nextStart)
        return String(prefix) + String(replacement)
    }

    private static var minimumRepairOverlapLength: Int {
        6
    }

    private static func longestCommonSubstring(_ lhs: String, _ rhs: String) -> (
        currentStart: Int,
        nextStart: Int,
        length: Int
    ) {
        let lhsCharacters = Array(lhs)
        let rhsCharacters = Array(rhs)
        guard !lhsCharacters.isEmpty, !rhsCharacters.isEmpty else {
            return (0, 0, 0)
        }

        var lengths = Array(
            repeating: Array(repeating: 0, count: rhsCharacters.count + 1),
            count: lhsCharacters.count + 1
        )
        var best = (currentStart: 0, nextStart: 0, length: 0)

        for lhsIndex in 1...lhsCharacters.count {
            for rhsIndex in 1...rhsCharacters.count {
                guard lhsCharacters[lhsIndex - 1] == rhsCharacters[rhsIndex - 1] else {
                    continue
                }

                let length = lengths[lhsIndex - 1][rhsIndex - 1] + 1
                lengths[lhsIndex][rhsIndex] = length
                if length > best.length {
                    best = (
                        currentStart: lhsIndex - length,
                        nextStart: rhsIndex - length,
                        length: length
                    )
                }
            }
        }

        return best
    }

    private static func joiner(between lhs: String, and rhs: String) -> String {
        guard let lhsLast = lhs.last, let rhsFirst = rhs.first else {
            return ""
        }
        if lhsLast.isWhitespace || rhsFirst.isWhitespace {
            return ""
        }
        if lhsLast.isASCIIAlphaNumeric && rhsFirst.isASCIIAlphaNumeric {
            return " "
        }
        return ""
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension Character {
    var isASCIIAlphaNumeric: Bool {
        unicodeScalars.count == 1 && unicodeScalars.allSatisfy { scalar in
            (65...90).contains(Int(scalar.value)) ||
                (97...122).contains(Int(scalar.value)) ||
                (48...57).contains(Int(scalar.value))
        }
    }
}

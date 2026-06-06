import Foundation

public enum RecognitionMode: String, Codable, Equatable, Sendable {
    case accurate
    case fast
}

public enum OutputDetailLevel: String, Codable, Equatable, Sendable {
    case textOnly
    case detailed
}

public enum TranscriberProfile: String, Codable, Equatable, Sendable {
    case dictation
    case transcription
}

public enum ContextualStringsTag: String, Codable, CaseIterable, Sendable {
    case general
    case commands
    case appTerms
    case people
    case technicalTerms
    case screenTerms
}

public struct ContextualStringsConfig: Codable, Equatable, Sendable {
    public static let defaultMaximumPhraseCount = 100

    public var stringsByTag: [ContextualStringsTag: [String]]
    public var maximumPhraseCount: Int

    public init(
        stringsByTag: [ContextualStringsTag: [String]] = [:],
        maximumPhraseCount: Int = Self.defaultMaximumPhraseCount
    ) {
        self.maximumPhraseCount = max(0, maximumPhraseCount)
        self.stringsByTag = Self.normalized(
            stringsByTag,
            maximumPhraseCount: self.maximumPhraseCount
        )
    }

    public init(
        general contextualStrings: [String],
        maximumPhraseCount: Int = Self.defaultMaximumPhraseCount
    ) {
        self.init(
            stringsByTag: [.general: contextualStrings],
            maximumPhraseCount: maximumPhraseCount
        )
    }

    public var flattenedStrings: [String] {
        orderedTags.flatMap { stringsByTag[$0] ?? [] }
    }

    public var phraseCount: Int {
        flattenedStrings.count
    }

    public func strings(for tag: ContextualStringsTag) -> [String] {
        stringsByTag[tag] ?? []
    }

    public func bounded(maximumPhraseCount: Int) -> ContextualStringsConfig {
        ContextualStringsConfig(
            stringsByTag: stringsByTag,
            maximumPhraseCount: maximumPhraseCount
        )
    }

    private var orderedTags: [ContextualStringsTag] {
        let knownTags = ContextualStringsTag.allCases.filter { stringsByTag[$0] != nil }
        let remainingTags = stringsByTag.keys
            .filter { !ContextualStringsTag.allCases.contains($0) }
            .sorted { $0.rawValue < $1.rawValue }
        return knownTags + remainingTags
    }

    private static func normalized(
        _ stringsByTag: [ContextualStringsTag: [String]],
        maximumPhraseCount: Int
    ) -> [ContextualStringsTag: [String]] {
        var seen: Set<String> = []
        var remaining = maximumPhraseCount
        var normalized: [ContextualStringsTag: [String]] = [:]

        let orderedTags = ContextualStringsTag.allCases.filter { stringsByTag[$0] != nil }
            + stringsByTag.keys
            .filter { !ContextualStringsTag.allCases.contains($0) }
            .sorted { $0.rawValue < $1.rawValue }

        for tag in orderedTags {
            guard remaining > 0 else {
                break
            }
            var phrases: [String] = []
            for phrase in stringsByTag[tag] ?? [] {
                guard remaining > 0 else {
                    break
                }
                let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    continue
                }
                guard seen.insert(trimmed).inserted else {
                    continue
                }
                phrases.append(trimmed)
                remaining -= 1
            }
            if !phrases.isEmpty {
                normalized[tag] = phrases
            }
        }

        return normalized
    }
}

public struct TranscriptionOptions: Codable, Equatable, Sendable {
    public static let defaultLocaleIdentifier = "ja-JP"

    public var locale: Locale
    public var contextualStrings: ContextualStringsConfig
    public var recognitionMode: RecognitionMode
    public var outputDetailLevel: OutputDetailLevel
    public var transcriberProfile: TranscriberProfile

    public init(
        locale: Locale = Locale(identifier: Self.defaultLocaleIdentifier),
        contextualStrings: ContextualStringsConfig = ContextualStringsConfig(),
        recognitionMode: RecognitionMode = .accurate,
        outputDetailLevel: OutputDetailLevel = .textOnly,
        transcriberProfile: TranscriberProfile = .dictation
    ) {
        self.locale = locale
        self.contextualStrings = contextualStrings
        self.recognitionMode = recognitionMode
        self.outputDetailLevel = outputDetailLevel
        self.transcriberProfile = transcriberProfile
    }
}

public struct TranscriptionOptionsBuilder: Sendable {
    public var localeIdentifier: String
    public var contextualStrings: ContextualStringsConfig
    public var recognitionMode: RecognitionMode
    public var outputDetailLevel: OutputDetailLevel
    public var transcriberProfile: TranscriberProfile

    public init(
        localeIdentifier: String = TranscriptionOptions.defaultLocaleIdentifier,
        contextualStrings: ContextualStringsConfig = ContextualStringsConfig(),
        recognitionMode: RecognitionMode = .accurate,
        outputDetailLevel: OutputDetailLevel = .textOnly,
        transcriberProfile: TranscriberProfile = .dictation
    ) {
        self.localeIdentifier = localeIdentifier
        self.contextualStrings = contextualStrings
        self.recognitionMode = recognitionMode
        self.outputDetailLevel = outputDetailLevel
        self.transcriberProfile = transcriberProfile
    }

    public func withRecognitionHints(_ hints: SpeechRecognitionHints) -> TranscriptionOptionsBuilder {
        var copy = self
        copy.contextualStrings = hints.contextualStringsConfig
        return copy
    }

    public func build() -> TranscriptionOptions {
        TranscriptionOptions(
            locale: Locale(identifier: localeIdentifier),
            contextualStrings: contextualStrings,
            recognitionMode: recognitionMode,
            outputDetailLevel: outputDetailLevel,
            transcriberProfile: transcriberProfile
        )
    }
}

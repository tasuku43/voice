import Foundation

public struct SpeechRecognitionHints: Equatable, Sendable {
    public var contextualStringsConfig: ContextualStringsConfig

    public var contextualStrings: [String] {
        contextualStringsConfig.flattenedStrings
    }

    public init(
        contextualStrings: [String] = [],
        maximumContextualStrings: Int = ContextualStringsConfig.defaultMaximumPhraseCount
    ) {
        self.contextualStringsConfig = ContextualStringsConfig(
            general: contextualStrings,
            maximumPhraseCount: maximumContextualStrings
        )
    }

    public init(contextualStringsConfig: ContextualStringsConfig) {
        self.contextualStringsConfig = contextualStringsConfig
    }
}

public struct SpeechRecognitionHintsUseCase: Sendable {
    public var maximumContextualStrings: Int

    public init(maximumContextualStrings: Int = 100) {
        self.maximumContextualStrings = maximumContextualStrings
    }

    public func hints(from entries: [DictionaryEntry]) -> SpeechRecognitionHints {
        var seen: Set<String> = []
        var stringsByTag: [ContextualStringsTag: [String]] = [:]
        var contextualStringCount = 0

        for entry in entries {
            let phrases = entry.recognitionHints.isEmpty
                ? [entry.canonical] + entry.spokenForms
                : entry.recognitionHints
            let tag = Self.tag(for: entry.kind)
            for phrase in phrases {
                let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    continue
                }
                guard seen.insert(trimmed).inserted else {
                    continue
                }
                stringsByTag[tag, default: []].append(trimmed)
                contextualStringCount += 1
                if contextualStringCount >= maximumContextualStrings {
                    return SpeechRecognitionHints(
                        contextualStringsConfig: ContextualStringsConfig(
                            stringsByTag: stringsByTag,
                            maximumPhraseCount: maximumContextualStrings
                        )
                    )
                }
            }
        }

        return SpeechRecognitionHints(
            contextualStringsConfig: ContextualStringsConfig(
                stringsByTag: stringsByTag,
                maximumPhraseCount: maximumContextualStrings
            )
        )
    }

    private static func tag(for kind: DictionaryEntryKind) -> ContextualStringsTag {
        switch kind {
        case .command:
            return .commands
        case .toolName, .productName:
            return .appTerms
        case .programmingLanguage, .library, .framework, .symbol, .projectTerm:
            return .technicalTerms
        case .fileName:
            return .screenTerms
        case .phrase:
            return .general
        }
    }
}

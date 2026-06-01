import Foundation

public struct SpeechRecognitionHints: Equatable, Sendable {
    public var contextualStrings: [String]

    public init(contextualStrings: [String] = []) {
        self.contextualStrings = contextualStrings
    }
}

public struct SpeechRecognitionHintsUseCase: Sendable {
    public var maximumContextualStrings: Int

    public init(maximumContextualStrings: Int = 100) {
        self.maximumContextualStrings = maximumContextualStrings
    }

    public func hints(from entries: [DictionaryEntry]) -> SpeechRecognitionHints {
        var seen: Set<String> = []
        var contextualStrings: [String] = []

        for entry in entries {
            let phrases = entry.recognitionHints.isEmpty
                ? [entry.canonical] + entry.spokenForms
                : entry.recognitionHints
            for phrase in phrases {
                let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    continue
                }
                guard seen.insert(trimmed).inserted else {
                    continue
                }
                contextualStrings.append(trimmed)
                if contextualStrings.count >= maximumContextualStrings {
                    return SpeechRecognitionHints(contextualStrings: contextualStrings)
                }
            }
        }

        return SpeechRecognitionHints(contextualStrings: contextualStrings)
    }
}

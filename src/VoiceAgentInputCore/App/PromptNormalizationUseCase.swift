import Foundation

public struct PromptNormalizationUseCase: Sendable {
    public var entries: [DictionaryEntry]

    public init(entries: [DictionaryEntry]) {
        self.entries = entries
    }

    public func normalize(rawText: String) -> NormalizationResult {
        let engine = NormalizationEngine(entries: entries)
        return engine.normalize(rawText)
    }

}

import Foundation

public struct AgentHistoryDictionaryLearningUseCase: Sendable {
    public var minimumOccurrences: Int

    public init(minimumOccurrences: Int = 2) {
        self.minimumOccurrences = minimumOccurrences
    }

    public func candidates(from texts: [String], scope: DictionaryScope = .user) -> [CorrectionCandidate] {
        var counts: [String: Int] = [:]
        for text in texts {
            for term in Self.extractTerms(from: text) {
                counts[term, default: 0] += 1
            }
        }

        return counts
            .filter { _, count in count >= minimumOccurrences }
            .compactMap { term, count in
                guard let spokenPhrase = Self.spokenPhrase(for: term) else {
                    return nil
                }
                return CorrectionCandidate(
                    rawPhrase: spokenPhrase,
                    correctedPhrase: term,
                    confidence: min(0.9, 0.55 + Double(count) * 0.05),
                    occurrenceCount: count,
                    reason: "Found \(count) uses in local agent history.",
                    suggestedScope: scope,
                    autoApplyAllowed: true
                )
            }
            .sorted { lhs, rhs in
                if lhs.occurrenceCount != rhs.occurrenceCount {
                    return lhs.occurrenceCount > rhs.occurrenceCount
                }
                return lhs.correctedPhrase < rhs.correctedPhrase
            }
    }

    public func entries(from texts: [String], scope: DictionaryScope = .user) -> [DictionaryEntry] {
        candidates(from: texts, scope: scope).map { candidate in
            DictionaryEntry(
                spokenForms: [candidate.rawPhrase],
                canonical: candidate.correctedPhrase,
                kind: Self.kind(for: candidate.correctedPhrase),
                scope: candidate.suggestedScope,
                confidence: candidate.confidence,
                autoApply: candidate.autoApplyAllowed
            )
        }
    }

    public static func extractTerms(from text: String) -> [String] {
        DeveloperTermSpeechRules.extractTerms(from: text)
    }

    public static func spokenPhrase(for term: String) -> String? {
        DeveloperTermSpeechRules.spokenPhrase(for: term)
    }

    private static func kind(for term: String) -> DictionaryEntryKind {
        let lower = term.lowercased()
        if ["api", "json", "yaml", "http", "https", "ui", "ux", "llm", "stt", "mcp", "cli"].contains(lower) {
            return .framework
        }
        if lower.contains("swift") || lower.contains("script") {
            return .programmingLanguage
        }
        if lower.contains("-") || lower.contains("_") {
            return .projectTerm
        }
        return .projectTerm
    }
}

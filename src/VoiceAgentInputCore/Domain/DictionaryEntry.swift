import Foundation

public struct DictionaryEntry: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var spokenForms: [String]
    public var canonical: String
    public var recognitionHints: [String]
    public var kind: DictionaryEntryKind
    public var scope: DictionaryScope
    public var confidence: Double
    public var autoApply: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        spokenForms: [String],
        canonical: String,
        recognitionHints: [String]? = nil,
        kind: DictionaryEntryKind,
        scope: DictionaryScope,
        confidence: Double,
        autoApply: Bool,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.id = id
        self.spokenForms = spokenForms
        self.canonical = canonical
        self.recognitionHints = Self.normalizedRecognitionHints(
            recognitionHints ?? Self.defaultRecognitionHints(canonical: canonical)
        )
        self.kind = kind
        self.scope = scope
        self.confidence = confidence
        self.autoApply = autoApply
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static func defaultRecognitionHints(canonical: String) -> [String] {
        normalizedRecognitionHints([canonical] + DeveloperTermSpeechRules.spokenPhrases(for: canonical))
    }

    public static func normalizedRecognitionHints(_ hints: [String]) -> [String] {
        var seen: Set<String> = []
        var normalized: [String] = []
        for hint in hints {
            let trimmed = hint.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }
            guard seen.insert(trimmed).inserted else {
                continue
            }
            normalized.append(trimmed)
        }
        return normalized
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case spokenForms
        case canonical
        case recognitionHints
        case kind
        case scope
        case confidence
        case autoApply
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let canonical = try container.decode(String.self, forKey: .canonical)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.spokenForms = try container.decode([String].self, forKey: .spokenForms)
        self.canonical = canonical
        self.recognitionHints = Self.normalizedRecognitionHints(
            try container.decodeIfPresent([String].self, forKey: .recognitionHints)
                ?? Self.defaultRecognitionHints(canonical: canonical)
        )
        self.kind = try container.decode(DictionaryEntryKind.self, forKey: .kind)
        self.scope = try container.decode(DictionaryScope.self, forKey: .scope)
        self.confidence = try container.decode(Double.self, forKey: .confidence)
        self.autoApply = try container.decode(Bool.self, forKey: .autoApply)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
            ?? Date(timeIntervalSince1970: 0)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
            ?? Date(timeIntervalSince1970: 0)
    }
}

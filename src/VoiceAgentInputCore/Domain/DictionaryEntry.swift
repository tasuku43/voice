import Foundation

public struct DictionaryEntry: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var spokenForms: [String]
    public var canonical: String
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
        self.kind = kind
        self.scope = scope
        self.confidence = confidence
        self.autoApply = autoApply
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

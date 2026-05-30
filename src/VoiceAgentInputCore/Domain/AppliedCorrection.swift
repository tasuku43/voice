import Foundation

public struct AppliedCorrection: Codable, Equatable, Sendable {
    public var original: String
    public var replacement: String
    public var canonical: String
    public var entryID: UUID
    public var kind: DictionaryEntryKind
    public var scope: DictionaryScope

    public init(
        original: String,
        replacement: String,
        canonical: String,
        entryID: UUID,
        kind: DictionaryEntryKind,
        scope: DictionaryScope
    ) {
        self.original = original
        self.replacement = replacement
        self.canonical = canonical
        self.entryID = entryID
        self.kind = kind
        self.scope = scope
    }
}

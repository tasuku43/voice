import Foundation

public struct LocalLearningDataDocumentCodec: Sendable {
    public init() {}

    public func encode(_ entries: [DictionaryEntry]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(entries)
    }

    public func decode(_ data: Data) throws -> [DictionaryEntry] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([DictionaryEntry].self, from: data)
    }
}

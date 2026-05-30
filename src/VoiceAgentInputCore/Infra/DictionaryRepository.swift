import Foundation

public protocol DictionaryRepository {
    func loadEntries() throws -> [DictionaryEntry]
    func saveEntries(_ entries: [DictionaryEntry]) throws
}

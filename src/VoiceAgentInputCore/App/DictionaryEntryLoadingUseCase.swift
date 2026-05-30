import Foundation

public struct DictionaryEntryLoadingUseCase {
    public var repository: any DictionaryRepository
    public var seedEntries: [DictionaryEntry]
    public var contextualEntries: [DictionaryEntry]

    public init(
        repository: any DictionaryRepository,
        seedEntries: [DictionaryEntry] = SeedDictionaries.codingAgentEntries,
        contextualEntries: [DictionaryEntry] = []
    ) {
        self.repository = repository
        self.seedEntries = seedEntries
        self.contextualEntries = contextualEntries
    }

    public func loadEntries() throws -> [DictionaryEntry] {
        seedEntries + contextualEntries + (try repository.loadEntries())
    }
}

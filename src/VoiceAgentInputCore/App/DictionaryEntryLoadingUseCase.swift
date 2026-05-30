import Foundation

public struct DictionaryEntryLoadingUseCase {
    public var repository: any DictionaryRepository
    public var seedEntries: [DictionaryEntry]

    public init(repository: any DictionaryRepository, seedEntries: [DictionaryEntry] = SeedDictionaries.codingAgentEntries) {
        self.repository = repository
        self.seedEntries = seedEntries
    }

    public func loadEntries() throws -> [DictionaryEntry] {
        seedEntries + (try repository.loadEntries())
    }
}

import Foundation

public struct DictionaryEntryLoadingUseCase {
    public var repository: any DictionaryRepository
    public var localContextModelRepository: (any LocalContextModelRepository)?
    public var seedEntries: [DictionaryEntry]
    public var contextualEntries: [DictionaryEntry]

    public init(
        repository: any DictionaryRepository,
        localContextModelRepository: (any LocalContextModelRepository)? = nil,
        seedEntries: [DictionaryEntry] = SeedDictionaries.codingAgentEntries,
        contextualEntries: [DictionaryEntry] = []
    ) {
        self.repository = repository
        self.localContextModelRepository = localContextModelRepository
        self.seedEntries = seedEntries
        self.contextualEntries = contextualEntries
    }

    public func loadEntries() throws -> [DictionaryEntry] {
        let approvedEntries = try repository.loadEntries()
        let modelEntries = try localContextModelRepository?.loadModel().postSTTEntries ?? []
        return deduplicated(seedEntries + contextualEntries + approvedEntries + modelEntries)
    }

    private func deduplicated(_ entries: [DictionaryEntry]) -> [DictionaryEntry] {
        var seen: Set<EntryIdentity> = []
        var result: [DictionaryEntry] = []

        for entry in entries {
            let key = EntryIdentity(entry: entry)
            guard seen.insert(key).inserted else {
                continue
            }
            result.append(entry)
        }

        return result
    }

    private struct EntryIdentity: Hashable {
        var canonical: String
        var scope: String
        var kind: String
        var spokenForms: [String]

        init(entry: DictionaryEntry) {
            self.canonical = entry.canonical
            self.scope = entry.scope.rawValue
            self.kind = entry.kind.rawValue
            self.spokenForms = entry.spokenForms
        }
    }
}

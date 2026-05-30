import Foundation

public struct LocalLearningDataUseCase {
    public var repository: any DictionaryRepository

    public init(repository: any DictionaryRepository) {
        self.repository = repository
    }

    public func exportApprovedEntries() throws -> [DictionaryEntry] {
        try repository.loadEntries()
    }

    public func importApprovedEntries(_ entries: [DictionaryEntry], merge: Bool = true) throws {
        if merge {
            var existingEntries = try repository.loadEntries()
            for entry in entries where !existingEntries.containsEquivalent(to: entry) {
                existingEntries.append(entry)
            }
            try repository.saveEntries(existingEntries)
        } else {
            try repository.saveEntries(entries)
        }
    }

    public func deleteAllLocalLearningData() throws {
        try repository.saveEntries([])
    }
}

private extension Array where Element == DictionaryEntry {
    func containsEquivalent(to entry: DictionaryEntry) -> Bool {
        contains { existing in
            existing.canonical == entry.canonical &&
                existing.scope == entry.scope &&
                Set(existing.spokenForms) == Set(entry.spokenForms)
        }
    }
}

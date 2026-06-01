import Foundation

public struct VoiceInputHistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var prompt: String

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        prompt: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.prompt = prompt
    }
}

public protocol VoiceInputHistoryRepository {
    func loadEntries() throws -> [VoiceInputHistoryEntry]
    func saveEntries(_ entries: [VoiceInputHistoryEntry]) throws
}

public struct VoiceInputHistoryUseCase {
    public var repository: any VoiceInputHistoryRepository
    public var maximumEntries: Int

    public init(repository: any VoiceInputHistoryRepository, maximumEntries: Int = 50) {
        self.repository = repository
        self.maximumEntries = max(1, maximumEntries)
    }

    @discardableResult
    public func record(prompt: String, createdAt: Date = Date()) throws -> VoiceInputHistoryEntry? {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            return nil
        }

        var entries = try repository.loadEntries()
        entries.removeAll { $0.prompt == trimmedPrompt }
        let entry = VoiceInputHistoryEntry(
            createdAt: createdAt,
            prompt: trimmedPrompt
        )
        entries.insert(entry, at: 0)
        if entries.count > maximumEntries {
            entries = Array(entries.prefix(maximumEntries))
        }
        try repository.saveEntries(entries)
        return entry
    }

    public func recentEntries() throws -> [VoiceInputHistoryEntry] {
        try repository.loadEntries()
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(maximumEntries)
            .map { $0 }
    }
}

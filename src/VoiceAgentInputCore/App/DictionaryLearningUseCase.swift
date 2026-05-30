import Foundation

public struct DictionaryLearningUseCase {
    public var repository: any DictionaryRepository
    public var now: @Sendable () -> Date

    public init(repository: any DictionaryRepository, now: @escaping @Sendable () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    @discardableResult
    public func approveCandidates(_ candidates: [CorrectionCandidate]) throws -> [DictionaryEntry] {
        var entries = try repository.loadEntries()
        let approvedEntries = candidates
            .filter { $0.approved && !$0.rejected }
            .map { entry(from: $0) }

        for approvedEntry in approvedEntries where !entries.containsEquivalent(to: approvedEntry) {
            entries.append(approvedEntry)
        }

        try repository.saveEntries(entries)
        return approvedEntries
    }

    private func entry(from candidate: CorrectionCandidate) -> DictionaryEntry {
        let timestamp = now()
        return DictionaryEntry(
            spokenForms: [candidate.rawPhrase],
            canonical: candidate.correctedPhrase,
            kind: .phrase,
            scope: candidate.suggestedScope,
            confidence: candidate.confidence,
            autoApply: candidate.autoApplyAllowed,
            createdAt: timestamp,
            updatedAt: timestamp
        )
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

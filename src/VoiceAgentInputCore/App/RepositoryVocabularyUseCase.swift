import Foundation

public struct RepositoryVocabularyUseCase {
    public init() {}

    public func entries(from context: RepositoryContext, filePaths: [String] = []) -> [DictionaryEntry] {
        var entries: [DictionaryEntry] = []
        let repositoryName = URL(fileURLWithPath: context.rootPath).lastPathComponent
        if !repositoryName.isEmpty {
            entries.append(DictionaryEntry(
                spokenForms: [repositoryName],
                canonical: repositoryName,
                kind: .projectTerm,
                scope: .repository,
                confidence: 0.7,
                autoApply: true
            ))
        }

        if let branchName = context.branchName, !branchName.isEmpty {
            entries.append(DictionaryEntry(
                spokenForms: [branchName],
                canonical: branchName,
                kind: .projectTerm,
                scope: .repository,
                confidence: 0.65,
                autoApply: true
            ))
        }

        for filePath in filePaths {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            guard !fileName.isEmpty else {
                continue
            }
            let entry = DictionaryEntry(
                spokenForms: [fileName],
                canonical: fileName,
                kind: .projectTerm,
                scope: .repository,
                confidence: 0.6,
                autoApply: true
            )
            if !entries.contains(where: { $0.canonical == entry.canonical && $0.scope == entry.scope }) {
                entries.append(entry)
            }
        }

        return entries
    }

    public func candidates(
        from context: RepositoryContext,
        filePaths: [String] = [],
        scope: DictionaryScope = .user
    ) -> [CorrectionCandidate] {
        vocabularyTerms(from: context, filePaths: filePaths).map { term in
            CorrectionCandidate(
                rawPhrase: term.spokenForms[0],
                correctedPhrase: term.canonical,
                confidence: term.confidence,
                occurrenceCount: 1,
                reason: "Found in configured repository vocabulary.",
                suggestedScope: scope,
                autoApplyAllowed: true
            )
        }
    }

    private func vocabularyTerms(from context: RepositoryContext, filePaths: [String]) -> [RepositoryVocabularyTerm] {
        var terms: [RepositoryVocabularyTerm] = []
        let repositoryName = URL(fileURLWithPath: context.rootPath).lastPathComponent
        if let term = vocabularyTerm(canonical: repositoryName, confidence: 0.7) {
            terms.append(term)
        }

        if let branchName = context.branchName, !branchName.isEmpty {
            if let term = vocabularyTerm(canonical: branchName, confidence: 0.65) {
                terms.append(term)
            }
        }

        for filePath in filePaths {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            guard let term = vocabularyTerm(canonical: fileName, confidence: 0.6) else { continue }
            if !terms.contains(where: { $0.canonical == term.canonical }) {
                terms.append(term)
            }
        }

        return terms
    }

    private func vocabularyTerm(canonical: String, confidence: Double) -> RepositoryVocabularyTerm? {
        let trimmed = canonical.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        let spokenForms = DeveloperTermSpeechRules.spokenPhrases(for: trimmed)
        guard !spokenForms.isEmpty else {
            return nil
        }
        return RepositoryVocabularyTerm(
            canonical: trimmed,
            spokenForms: spokenForms,
            confidence: confidence
        )
    }
}

private struct RepositoryVocabularyTerm {
    var canonical: String
    var spokenForms: [String]
    var confidence: Double

}

import Foundation

public struct RepositoryVocabularyUseCase {
    public init() {}

    public func entries(from context: RepositoryContext) -> [DictionaryEntry] {
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

        return entries
    }
}

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
}

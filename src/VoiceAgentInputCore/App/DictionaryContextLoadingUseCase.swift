import Foundation

public protocol RepositoryVocabularyFilePathProvider {
    func trackedVocabularyFilePaths(rootPath: String) throws -> [String]
}

public struct DictionaryContextLoadingUseCase {
    public var repository: any DictionaryRepository
    public var repositoryContextProvider: any RepositoryContextProvider
    public var repositoryVocabularyFilePathProvider: (any RepositoryVocabularyFilePathProvider)?
    public var seedEntries: [DictionaryEntry]

    public init(
        repository: any DictionaryRepository,
        repositoryContextProvider: any RepositoryContextProvider,
        repositoryVocabularyFilePathProvider: (any RepositoryVocabularyFilePathProvider)? = nil,
        seedEntries: [DictionaryEntry] = SeedDictionaries.codingAgentEntries
    ) {
        self.repository = repository
        self.repositoryContextProvider = repositoryContextProvider
        self.repositoryVocabularyFilePathProvider = repositoryVocabularyFilePathProvider
        self.seedEntries = seedEntries
    }

    public func loadEntries(startingAt repositoryURL: URL) throws -> [DictionaryEntry] {
        try DictionaryEntryLoadingUseCase(
            repository: repository,
            seedEntries: seedEntries,
            contextualEntries: loadRepositoryVocabularyEntries(startingAt: repositoryURL)
        ).loadEntries()
    }

    private func loadRepositoryVocabularyEntries(startingAt repositoryURL: URL) -> [DictionaryEntry] {
        guard let context = try? repositoryContextProvider.currentContext(startingAt: repositoryURL) else {
            return []
        }
        let filePaths = (try? repositoryVocabularyFilePathProvider?.trackedVocabularyFilePaths(rootPath: context.rootPath)) ?? []
        return RepositoryVocabularyUseCase().entries(from: context, filePaths: filePaths)
    }
}

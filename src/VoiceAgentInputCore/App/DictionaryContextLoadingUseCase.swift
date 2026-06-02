import Foundation

public protocol RepositoryVocabularyFilePathProvider {
    func trackedVocabularyFilePaths(rootPath: String) throws -> [String]
}

public struct DictionaryContextLoadingUseCase {
    public var repositoryContextProvider: any RepositoryContextProvider
    public var repositoryVocabularyFilePathProvider: (any RepositoryVocabularyFilePathProvider)?
    public var seedEntries: [DictionaryEntry]

    public init(
        repositoryContextProvider: any RepositoryContextProvider,
        repositoryVocabularyFilePathProvider: (any RepositoryVocabularyFilePathProvider)? = nil,
        seedEntries: [DictionaryEntry] = SeedDictionaries.codingAgentEntries
    ) {
        self.repositoryContextProvider = repositoryContextProvider
        self.repositoryVocabularyFilePathProvider = repositoryVocabularyFilePathProvider
        self.seedEntries = seedEntries
    }

    public func loadEntries(startingAt repositoryURL: URL) throws -> [DictionaryEntry] {
        _ = repositoryURL
        return try DictionaryEntryLoadingUseCase(
            seedEntries: seedEntries
        ).loadEntries()
    }
}

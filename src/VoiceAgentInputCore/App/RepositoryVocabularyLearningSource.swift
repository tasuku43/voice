import Foundation

public struct RepositoryVocabularyLearningSource: CorrectionCandidateLearningSource {
    public var startingURL: URL
    public var repositoryContextProvider: any RepositoryContextProvider
    public var repositoryVocabularyFilePathProvider: (any RepositoryVocabularyFilePathProvider)?

    public init(
        startingURL: URL,
        repositoryContextProvider: any RepositoryContextProvider,
        repositoryVocabularyFilePathProvider: (any RepositoryVocabularyFilePathProvider)? = nil
    ) {
        self.startingURL = startingURL
        self.repositoryContextProvider = repositoryContextProvider
        self.repositoryVocabularyFilePathProvider = repositoryVocabularyFilePathProvider
    }

    public var sourceKind: LearningSourceKind {
        .repositoryVocabulary
    }

    public func learningTexts() throws -> [LearningText] {
        guard let context = try repositoryContextProvider.currentContext(startingAt: startingURL) else {
            return []
        }
        let filePaths = try repositoryVocabularyFilePathProvider?.trackedVocabularyFilePaths(rootPath: context.rootPath) ?? []
        let text = ([context.rootPath, context.branchName].compactMap { $0 } + filePaths)
            .joined(separator: "\n")
        guard !text.isEmpty else {
            return []
        }
        return [
            LearningText(
                sourceKind: .repositoryVocabulary,
                text: text,
                metadata: [
                    "rootPath": context.rootPath,
                    "branchName": context.branchName ?? ""
                ]
            )
        ]
    }

    public func correctionCandidates(scope: DictionaryScope) throws -> [CorrectionCandidate] {
        guard let context = try repositoryContextProvider.currentContext(startingAt: startingURL) else {
            return []
        }
        let filePaths = try repositoryVocabularyFilePathProvider?.trackedVocabularyFilePaths(rootPath: context.rootPath) ?? []
        return RepositoryVocabularyUseCase().candidates(from: context, filePaths: filePaths, scope: scope)
    }
}

import Foundation

public struct LocalContextModelStatusUseCase: Sendable {
    public init() {}

    public func warnings(
        model: LocalContextModel,
        configuredRepositoryPath: String?
    ) -> [String] {
        var warnings: [String] = []
        if model.lastRebuiltAt == nil {
            warnings.append("Local context model has not been rebuilt yet.")
        }

        let modelSourceKinds = Set(model.sourceKinds)
        let repositorySourceKind = LearningSourceKind.repositoryVocabulary.rawValue
        let trimmedRepositoryPath = configuredRepositoryPath?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasConfiguredRepository = !trimmedRepositoryPath.isEmpty

        if hasConfiguredRepository, !modelSourceKinds.contains(repositorySourceKind) {
            warnings.append("Repository folder is configured, but repository vocabulary is not in the saved model. Rebuild to include it.")
        }
        if !hasConfiguredRepository, modelSourceKinds.contains(repositorySourceKind) {
            warnings.append("Saved model includes repository vocabulary, but no repository folder is configured. Rebuild if this source should no longer be used.")
        }

        return warnings
    }
}

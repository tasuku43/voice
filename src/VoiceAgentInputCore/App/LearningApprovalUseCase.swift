import Foundation

public struct LearningApprovalUseCase {
    public var repository: any DictionaryRepository
    public var candidateApprovalUseCase: CandidateApprovalUseCase
    public var now: @Sendable () -> Date

    public init(
        repository: any DictionaryRepository,
        candidateApprovalUseCase: CandidateApprovalUseCase = CandidateApprovalUseCase(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.repository = repository
        self.candidateApprovalUseCase = candidateApprovalUseCase
        self.now = now
    }

    @discardableResult
    public func approveSelectedCandidates(
        _ candidates: [CorrectionCandidate],
        selectedIndexes: Set<Int>
    ) throws -> [DictionaryEntry] {
        let reviewedCandidates = candidateApprovalUseCase.approveCandidates(
            candidates,
            selectedIndexes: selectedIndexes
        )
        return try DictionaryLearningUseCase(
            repository: repository,
            now: now
        ).approveCandidates(reviewedCandidates)
    }
}

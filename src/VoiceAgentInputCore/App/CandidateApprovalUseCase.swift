import Foundation

public struct CandidateApprovalUseCase: Sendable {
    public init() {}

    public func approveCandidates(_ candidates: [CorrectionCandidate], selectedIndexes: Set<Int>) -> [CorrectionCandidate] {
        candidates.enumerated().map { index, candidate in
            var updated = candidate
            if selectedIndexes.contains(index) {
                updated.approved = true
                updated.rejected = false
            } else {
                updated.approved = false
                updated.rejected = true
            }
            return updated
        }
    }
}

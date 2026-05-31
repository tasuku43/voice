import Foundation

public protocol LearningCandidateReviewer: Sendable {
    func review(candidates: [CorrectionCandidate], diff: PromptDiff) async throws -> [CorrectionCandidate]
}

public struct NoOpLearningCandidateReviewer: LearningCandidateReviewer, Sendable {
    public init() {}

    public func review(candidates: [CorrectionCandidate], diff: PromptDiff) async throws -> [CorrectionCandidate] {
        candidates
    }
}

public struct DetectorBackedLearningCandidateReviewer: LearningCandidateReviewer, Sendable {
    public var detector: any VoiceMisrecognitionDetector

    public init(detector: any VoiceMisrecognitionDetector) {
        self.detector = detector
    }

    public func review(candidates: [CorrectionCandidate], diff: PromptDiff) async throws -> [CorrectionCandidate] {
        candidates.map { candidate in
            let evidence = detector.evidence(
                rawPhrase: candidate.rawPhrase,
                correctedPhrase: candidate.correctedPhrase,
                diff: diff
            )
            var reviewed = candidate
            reviewed.reason = evidence.reason
            reviewed.confidence = candidate.dangerous ? min(0.4, evidence.confidence) : evidence.confidence
            reviewed.autoApplyAllowed = candidate.autoApplyAllowed && !candidate.dangerous
            return reviewed
        }
    }
}

public struct PromptEditLearningUseCase: Sendable {
    public var previewUseCase: PromptPreviewUseCase
    public var candidateReviewer: any LearningCandidateReviewer

    public init(
        previewUseCase: PromptPreviewUseCase,
        candidateReviewer: any LearningCandidateReviewer = NoOpLearningCandidateReviewer()
    ) {
        self.previewUseCase = previewUseCase
        self.candidateReviewer = candidateReviewer
    }

    public func confirm(
        preview: PromptPreview,
        finalEditedPrompt: String? = nil,
        suggestedScope: DictionaryScope = .user
    ) async throws -> ConfirmedPrompt {
        let confirmed = previewUseCase.confirm(
            preview: preview,
            finalEditedPrompt: finalEditedPrompt,
            suggestedScope: suggestedScope
        )
        let promptToInsert = finalEditedPrompt ?? preview.correctedPrompt
        let diff = PromptDiff(
            rawText: preview.rawTranscript,
            autoCorrectedText: preview.correctedPrompt,
            finalEditedText: promptToInsert
        )
        let reviewedCandidates: [CorrectionCandidate]
        do {
            reviewedCandidates = try await candidateReviewer.review(
                candidates: confirmed.candidates,
                diff: diff
            )
        } catch {
            reviewedCandidates = confirmed.candidates
        }
        return ConfirmedPrompt(
            promptToInsert: confirmed.promptToInsert,
            candidates: reviewedCandidates,
            shouldSubmitAutomatically: confirmed.shouldSubmitAutomatically
        )
    }
}

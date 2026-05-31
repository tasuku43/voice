import Foundation

public struct VoiceMisrecognitionEvidence: Equatable, Sendable {
    public var confidence: Double
    public var reason: String

    public init(confidence: Double, reason: String) {
        self.confidence = confidence
        self.reason = reason
    }
}

public protocol VoiceMisrecognitionDetector: Sendable {
    func evidence(rawPhrase: String, correctedPhrase: String, diff: PromptDiff) -> VoiceMisrecognitionEvidence
}

public struct RuleBasedVoiceMisrecognitionDetector: VoiceMisrecognitionDetector, Sendable {
    public init() {}

    public func evidence(rawPhrase: String, correctedPhrase: String, diff: PromptDiff) -> VoiceMisrecognitionEvidence {
        let correctedWasUserEdit = !diff.autoCorrectedText.contains(correctedPhrase) &&
            diff.finalEditedText.contains(correctedPhrase)
        let rawWasTranscript = diff.rawText.contains(rawPhrase)
        let confidence = correctedWasUserEdit && rawWasTranscript ? 0.76 : 0.62
        let reason = correctedWasUserEdit
            ? "Likely voice misrecognition: raw transcript contained '\(rawPhrase)' and the user edited it to '\(correctedPhrase)'."
            : "Likely voice vocabulary match: raw transcript contained '\(rawPhrase)' and final text used '\(correctedPhrase)'."
        return VoiceMisrecognitionEvidence(confidence: confidence, reason: reason)
    }
}

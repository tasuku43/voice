import Foundation

public enum VoiceInputModeDecision: Equatable, Sendable {
    case quickPaste(ConfirmedPrompt)
    case learningPreview(PromptPreview)
}

public struct VoiceInputModeDecisionUseCase: Sendable {
    public init() {}

    public func decide(mode: VoiceInputMode, preview: PromptPreview) -> VoiceInputModeDecision {
        switch mode {
        case .quickPaste:
            return .quickPaste(ConfirmedPrompt(
                promptToInsert: preview.correctedPrompt,
                candidates: []
            ))
        case .learningPreview:
            return .learningPreview(preview)
        }
    }
}

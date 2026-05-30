import Foundation

public struct VoiceInputFlowUseCase {
    public var speechEngine: any SpeechToTextEngine
    public var previewUseCase: PromptPreviewUseCase

    public init(speechEngine: any SpeechToTextEngine, previewUseCase: PromptPreviewUseCase) {
        self.speechEngine = speechEngine
        self.previewUseCase = previewUseCase
    }

    public init(speechEngine: any SpeechToTextEngine, entries: [DictionaryEntry]) {
        self.speechEngine = speechEngine
        self.previewUseCase = PromptPreviewUseCase(entries: entries)
    }

    public func transcribeAndPreview(mockAudioText: String) async throws -> PromptPreview {
        let rawTranscript = try await speechEngine.transcribeMockText(mockAudioText)
        return previewUseCase.preview(rawTranscript: rawTranscript)
    }
}

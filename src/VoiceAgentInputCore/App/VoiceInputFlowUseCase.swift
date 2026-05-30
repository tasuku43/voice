import Foundation

public struct VoiceInputFlowUseCase {
    public var audioRecorder: (any AudioRecorder)?
    public var speechEngine: any SpeechToTextEngine
    public var previewUseCase: PromptPreviewUseCase

    public init(audioRecorder: (any AudioRecorder)? = nil, speechEngine: any SpeechToTextEngine, previewUseCase: PromptPreviewUseCase) {
        self.audioRecorder = audioRecorder
        self.speechEngine = speechEngine
        self.previewUseCase = previewUseCase
    }

    public init(audioRecorder: (any AudioRecorder)? = nil, speechEngine: any SpeechToTextEngine, entries: [DictionaryEntry]) {
        self.audioRecorder = audioRecorder
        self.speechEngine = speechEngine
        self.previewUseCase = PromptPreviewUseCase(entries: entries)
    }

    public func recordTranscribeAndPreview() async throws -> PromptPreview {
        guard let audioRecorder else {
            throw VoiceInputFlowError.audioRecorderUnavailable
        }
        let audio = try await audioRecorder.recordOnce()
        let transcript = try await speechEngine.transcribe(audio: audio)
        return previewUseCase.preview(rawTranscript: transcript.text)
    }

    public func transcribeAndPreview(mockAudioText: String) async throws -> PromptPreview {
        let rawTranscript = try await speechEngine.transcribeMockText(mockAudioText)
        return previewUseCase.preview(rawTranscript: rawTranscript)
    }
}

public enum VoiceInputFlowError: Error, Equatable {
    case audioRecorderUnavailable
}

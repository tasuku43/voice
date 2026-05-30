import Foundation

public struct VoiceInputFlowUseCase {
    public var audioRecorder: (any AudioRecorder)?
    public var microphonePermissionProvider: (any MicrophonePermissionProvider)?
    public var speechEngine: any SpeechToTextEngine
    public var previewUseCase: PromptPreviewUseCase

    public init(
        audioRecorder: (any AudioRecorder)? = nil,
        microphonePermissionProvider: (any MicrophonePermissionProvider)? = nil,
        speechEngine: any SpeechToTextEngine,
        previewUseCase: PromptPreviewUseCase
    ) {
        self.audioRecorder = audioRecorder
        self.microphonePermissionProvider = microphonePermissionProvider
        self.speechEngine = speechEngine
        self.previewUseCase = previewUseCase
    }

    public init(
        audioRecorder: (any AudioRecorder)? = nil,
        microphonePermissionProvider: (any MicrophonePermissionProvider)? = nil,
        speechEngine: any SpeechToTextEngine,
        entries: [DictionaryEntry]
    ) {
        self.audioRecorder = audioRecorder
        self.microphonePermissionProvider = microphonePermissionProvider
        self.speechEngine = speechEngine
        self.previewUseCase = PromptPreviewUseCase(entries: entries)
    }

    public func recordTranscribeAndPreview() async throws -> PromptPreview {
        guard let audioRecorder else {
            throw VoiceInputFlowError.audioRecorderUnavailable
        }
        if let microphonePermissionProvider {
            do {
                try await MicrophonePermissionUseCase(provider: microphonePermissionProvider).ensureRecordingAllowed()
            } catch let error as MicrophonePermissionError {
                if case let .recordingNotAllowed(status) = error {
                    throw VoiceInputFlowError.microphonePermissionDenied(status: status)
                }
                throw error
            }
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
    case microphonePermissionDenied(status: MicrophonePermissionStatus)
}

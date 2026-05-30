import Foundation

public struct VoiceInputFlowUseCase {
    public var audioRecorder: (any AudioRecorder)?
    public var microphonePermissionProvider: (any MicrophonePermissionProvider)?
    public var speechEngine: any SpeechToTextEngine
    public var previewUseCase: PromptPreviewUseCase
    public var refiner: any PromptRefiner

    public init(
        audioRecorder: (any AudioRecorder)? = nil,
        microphonePermissionProvider: (any MicrophonePermissionProvider)? = nil,
        speechEngine: any SpeechToTextEngine,
        previewUseCase: PromptPreviewUseCase,
        refiner: any PromptRefiner = NoOpPromptRefiner()
    ) {
        self.audioRecorder = audioRecorder
        self.microphonePermissionProvider = microphonePermissionProvider
        self.speechEngine = speechEngine
        self.previewUseCase = previewUseCase
        self.refiner = refiner
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
        self.refiner = NoOpPromptRefiner()
    }

    public func recordTranscribeAndPreview() async throws -> PromptPreview {
        try await pipeline().run().preview
    }

    public func transcribeAndPreview(mockAudioText: String) async throws -> PromptPreview {
        try await pipeline().run(mockAudioText: mockAudioText).preview
    }

    public func recordTranscribeNormalizeAndRefine() async throws -> VoiceInputPipelineResult {
        try await pipeline().run()
    }

    private func pipeline() -> VoiceInputPipeline {
        VoiceInputPipeline(
            audioRecorder: audioRecorder,
            microphonePermissionProvider: microphonePermissionProvider,
            speechEngine: speechEngine,
            refiner: refiner,
            normalizationContext: NormalizationContext(entries: previewUseCase.normalizationUseCase.entries)
        )
    }
}

public enum VoiceInputFlowError: Error, Equatable {
    case audioRecorderUnavailable
    case microphonePermissionDenied(status: MicrophonePermissionStatus)
}

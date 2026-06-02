import Foundation

public enum VoiceInputPipelineError: Error, Equatable {
    case audioRecorderUnavailable
    case microphonePermissionDenied(status: MicrophonePermissionStatus)
}

public struct VoiceInputPipelineResult: Equatable, Sendable {
    public var transcript: Transcript
    public var normalizedPrompt: NormalizedPrompt
    public var refinedPrompt: RefinedPrompt
    public var preview: PromptPreview

    public init(
        transcript: Transcript,
        normalizedPrompt: NormalizedPrompt,
        refinedPrompt: RefinedPrompt,
        preview: PromptPreview
    ) {
        self.transcript = transcript
        self.normalizedPrompt = normalizedPrompt
        self.refinedPrompt = refinedPrompt
        self.preview = preview
    }

    public init(promptProcessingResult: PromptProcessingPipelineResult) {
        self.init(
            transcript: promptProcessingResult.transcript,
            normalizedPrompt: promptProcessingResult.normalizedPrompt,
            refinedPrompt: promptProcessingResult.refinedPrompt,
            preview: promptProcessingResult.preview
        )
    }
}

public struct VoiceInputPipeline {
    public var audioRecorder: (any AudioRecorder)?
    public var microphonePermissionProvider: (any MicrophonePermissionProvider)?
    public var speechEngine: any SpeechToTextEngine
    public var normalizer: any PromptNormalizer
    public var refiner: any PromptRefiner
    public var normalizationContext: NormalizationContext
    public var refinementInstruction: RefinementInstruction
    public var recordedAudioHandler: (@Sendable (RecordedAudio) -> Void)?

    public init(
        audioRecorder: (any AudioRecorder)? = nil,
        microphonePermissionProvider: (any MicrophonePermissionProvider)? = nil,
        speechEngine: any SpeechToTextEngine,
        normalizer: any PromptNormalizer = DictionaryPromptNormalizer(),
        refiner: any PromptRefiner = NoOpPromptRefiner(),
        normalizationContext: NormalizationContext,
        refinementInstruction: RefinementInstruction = RefinementInstruction(),
        recordedAudioHandler: (@Sendable (RecordedAudio) -> Void)? = nil
    ) {
        self.audioRecorder = audioRecorder
        self.microphonePermissionProvider = microphonePermissionProvider
        self.speechEngine = speechEngine
        self.normalizer = normalizer
        self.refiner = refiner
        self.normalizationContext = normalizationContext
        self.refinementInstruction = refinementInstruction
        self.recordedAudioHandler = recordedAudioHandler
    }

    public func run() async throws -> VoiceInputPipelineResult {
        guard let audioRecorder else {
            throw VoiceInputPipelineError.audioRecorderUnavailable
        }
        if let microphonePermissionProvider {
            do {
                try await MicrophonePermissionUseCase(provider: microphonePermissionProvider).ensureRecordingAllowed()
            } catch let error as MicrophonePermissionError {
                if case let .recordingNotAllowed(status) = error {
                    throw VoiceInputPipelineError.microphonePermissionDenied(status: status)
                }
                throw error
            }
        }
        let audio = try await audioRecorder.recordOnce()
        recordedAudioHandler?(audio)
        let transcript = try await speechEngine.transcribe(audio: audio)
        return try await run(transcript: transcript)
    }

    public func run(mockAudioText: String) async throws -> VoiceInputPipelineResult {
        let rawTranscript = try await speechEngine.transcribeMockText(mockAudioText)
        return try await run(transcript: Transcript(text: rawTranscript))
    }

    public func run(transcript: Transcript) async throws -> VoiceInputPipelineResult {
        let result = try await promptProcessingPipeline().process(transcript: transcript)
        return VoiceInputPipelineResult(promptProcessingResult: result)
    }

    private func promptProcessingPipeline() -> PromptProcessingPipeline {
        PromptProcessingPipeline(
            normalizer: normalizer,
            refiner: refiner,
            normalizationContext: normalizationContext,
            refinementInstruction: refinementInstruction
        )
    }
}

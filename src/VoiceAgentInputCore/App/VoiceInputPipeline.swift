import Foundation

public enum VoiceInputPipelineError: Error, Equatable {
    case audioRecorderUnavailable
    case microphonePermissionDenied(status: MicrophonePermissionStatus)
}

public struct VoiceInputPipelineResult: Equatable, Sendable {
    public var transcript: Transcript
    public var normalizedPrompt: NormalizedPrompt
    public var refinement: PromptTextRefinementResult?
    public var insertion: PromptInsertion

    public init(
        transcript: Transcript,
        normalizedPrompt: NormalizedPrompt,
        refinement: PromptTextRefinementResult? = nil,
        insertion: PromptInsertion
    ) {
        self.transcript = transcript
        self.normalizedPrompt = normalizedPrompt
        self.refinement = refinement
        self.insertion = insertion
    }

    public init(promptProcessingResult: PromptProcessingPipelineResult) {
        self.init(
            transcript: promptProcessingResult.transcript,
            normalizedPrompt: promptProcessingResult.normalizedPrompt,
            refinement: promptProcessingResult.refinement,
            insertion: promptProcessingResult.insertion
        )
    }
}

public struct VoiceInputPipeline {
    public var audioRecorder: (any AudioRecorder)?
    public var microphonePermissionProvider: (any MicrophonePermissionProvider)?
    public var speechEngine: any SpeechToTextEngine
    public var normalizer: any PromptNormalizer
    public var normalizationContext: NormalizationContext
    public var textRefiner: (any PromptTextRefiner)?

    public init(
        audioRecorder: (any AudioRecorder)? = nil,
        microphonePermissionProvider: (any MicrophonePermissionProvider)? = nil,
        speechEngine: any SpeechToTextEngine,
        normalizer: any PromptNormalizer = DictionaryPromptNormalizer(),
        normalizationContext: NormalizationContext,
        textRefiner: (any PromptTextRefiner)? = nil
    ) {
        self.audioRecorder = audioRecorder
        self.microphonePermissionProvider = microphonePermissionProvider
        self.speechEngine = speechEngine
        self.normalizer = normalizer
        self.normalizationContext = normalizationContext
        self.textRefiner = textRefiner
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
        let transcript = try await speechEngine.transcribe(audio: audio)
        return try await run(transcript: transcript)
    }

    public func run(transcript: Transcript) async throws -> VoiceInputPipelineResult {
        let result = try await promptProcessingPipeline().process(transcript: transcript)
        return VoiceInputPipelineResult(promptProcessingResult: result)
    }

    private func promptProcessingPipeline() -> PromptProcessingPipeline {
        PromptProcessingPipeline(
            normalizer: normalizer,
            normalizationContext: normalizationContext,
            textRefiner: textRefiner
        )
    }
}

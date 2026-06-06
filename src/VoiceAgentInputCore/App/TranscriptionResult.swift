import Foundation

public struct TranscriptionResult: Codable, Equatable, Sendable {
    public var text: String
    public var segments: [TranscriptionSegment]
    public var alternatives: [TranscriptionAlternative]
    public var metadata: TranscriptionMetadata

    public init(
        text: String,
        segments: [TranscriptionSegment] = [],
        alternatives: [TranscriptionAlternative] = [],
        metadata: TranscriptionMetadata
    ) {
        self.text = text
        self.segments = segments
        self.alternatives = alternatives
        self.metadata = metadata
    }

    public var transcript: Transcript {
        Transcript(
            text: text,
            localeIdentifier: metadata.localeIdentifier,
            confidence: metadata.confidence
        )
    }
}

public struct TranscriptionSegment: Codable, Equatable, Sendable {
    public var text: String
    public var startTimeSeconds: Double?
    public var durationSeconds: Double?
    public var confidence: Double?
    public var isFinal: Bool

    public init(
        text: String,
        startTimeSeconds: Double? = nil,
        durationSeconds: Double? = nil,
        confidence: Double? = nil,
        isFinal: Bool = true
    ) {
        self.text = text
        self.startTimeSeconds = startTimeSeconds
        self.durationSeconds = durationSeconds
        self.confidence = confidence
        self.isFinal = isFinal
    }
}

public struct TranscriptionAlternative: Codable, Equatable, Sendable {
    public var text: String
    public var confidence: Double?

    public init(text: String, confidence: Double? = nil) {
        self.text = text
        self.confidence = confidence
    }
}

public struct TranscriptionMetadata: Codable, Equatable, Sendable {
    public var engine: String
    public var localeIdentifier: String
    public var durationSeconds: Double?
    public var confidence: Double?
    public var contextualStringCount: Int
    public var recognitionMode: RecognitionMode
    public var outputDetailLevel: OutputDetailLevel
    public var transcriberProfile: TranscriberProfile

    public init(
        engine: String,
        localeIdentifier: String,
        durationSeconds: Double? = nil,
        confidence: Double? = nil,
        contextualStringCount: Int = 0,
        recognitionMode: RecognitionMode = .accurate,
        outputDetailLevel: OutputDetailLevel = .textOnly,
        transcriberProfile: TranscriberProfile = .dictation
    ) {
        self.engine = engine
        self.localeIdentifier = localeIdentifier
        self.durationSeconds = durationSeconds
        self.confidence = confidence
        self.contextualStringCount = contextualStringCount
        self.recognitionMode = recognitionMode
        self.outputDetailLevel = outputDetailLevel
        self.transcriberProfile = transcriberProfile
    }
}

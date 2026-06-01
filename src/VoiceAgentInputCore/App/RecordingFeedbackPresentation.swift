import Foundation

public enum RecordingFeedbackPhase: Equatable, Sendable {
    case connecting
    case listening
    case quiet
}

public struct RecordingFeedbackPresentation: Equatable, Sendable {
    public var phase: RecordingFeedbackPhase
    public var title: String
    public var guidance: String
    public var elapsedText: String
    public var meterLevels: [Double]
    public var accessibilityLabel: String

    public init(
        phase: RecordingFeedbackPhase,
        title: String,
        guidance: String,
        elapsedText: String,
        meterLevels: [Double],
        accessibilityLabel: String
    ) {
        self.phase = phase
        self.title = title
        self.guidance = guidance
        self.elapsedText = elapsedText
        self.meterLevels = meterLevels
        self.accessibilityLabel = accessibilityLabel
    }
}

public struct RecordingFeedbackPresentationUseCase: Sendable {
    public init() {}

    public func presentation(
        level: Float?,
        hasDetectedVoice: Bool,
        elapsedSeconds: TimeInterval,
        triggerMode: VoiceInputTriggerMode
    ) -> RecordingFeedbackPresentation {
        let phase = phase(level: level, hasDetectedVoice: hasDetectedVoice)
        let title: String
        switch phase {
        case .connecting:
            title = "Getting ready"
        case .listening:
            title = "Listening"
        case .quiet:
            title = "Quiet"
        }

        let guidance: String
        switch triggerMode {
        case .pressAndHold:
            guidance = "Release shortcut to paste"
        case .toggleRecording:
            guidance = "Press shortcut again to paste"
        }

        let elapsedText = Self.elapsedText(for: elapsedSeconds)
        return RecordingFeedbackPresentation(
            phase: phase,
            title: title,
            guidance: guidance,
            elapsedText: elapsedText,
            meterLevels: meterLevels(level: level, phase: phase, elapsedSeconds: elapsedSeconds),
            accessibilityLabel: "\(title). \(guidance). \(elapsedText)."
        )
    }

    private func phase(level: Float?, hasDetectedVoice: Bool) -> RecordingFeedbackPhase {
        guard let level else {
            return .connecting
        }
        if level > 0.08 || !hasDetectedVoice {
            return .listening
        }
        return .quiet
    }

    private func meterLevels(
        level: Float?,
        phase: RecordingFeedbackPhase,
        elapsedSeconds: TimeInterval
    ) -> [Double] {
        let baseLevel = min(max(Double(level ?? 0), 0), 1)
        return (0..<10).map { index in
            let wave = (sin(elapsedSeconds * 7 + Double(index) * 0.85) + 1) / 2
            switch phase {
            case .connecting:
                return 0.16 + wave * 0.18
            case .quiet:
                return 0.12 + wave * 0.08
            case .listening:
                return min(1, 0.16 + baseLevel * 0.78 + wave * 0.22)
            }
        }
    }

    private static func elapsedText(for elapsedSeconds: TimeInterval) -> String {
        let clampedSeconds = max(0, Int(elapsedSeconds.rounded(.down)))
        return "\(clampedSeconds / 60):\(String(format: "%02d", clampedSeconds % 60))"
    }
}

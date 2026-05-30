import Foundation

public struct PermissionStatusSnapshot: Equatable, Sendable {
    public var microphone: MicrophonePermissionStatus
    public var speechRecognition: SpeechRecognitionPermissionStatus
    public var accessibility: AccessibilityPermissionStatus

    public init(
        microphone: MicrophonePermissionStatus,
        speechRecognition: SpeechRecognitionPermissionStatus,
        accessibility: AccessibilityPermissionStatus
    ) {
        self.microphone = microphone
        self.speechRecognition = speechRecognition
        self.accessibility = accessibility
    }
}

public struct PermissionStatusUseCase {
    public var microphonePermissionProvider: any MicrophonePermissionProvider
    public var speechRecognitionPermissionProvider: any SpeechRecognitionPermissionProvider
    public var accessibilityPermissionProvider: any AccessibilityPermissionProvider

    public init(
        microphonePermissionProvider: any MicrophonePermissionProvider,
        speechRecognitionPermissionProvider: any SpeechRecognitionPermissionProvider,
        accessibilityPermissionProvider: any AccessibilityPermissionProvider
    ) {
        self.microphonePermissionProvider = microphonePermissionProvider
        self.speechRecognitionPermissionProvider = speechRecognitionPermissionProvider
        self.accessibilityPermissionProvider = accessibilityPermissionProvider
    }

    public func currentStatus() -> PermissionStatusSnapshot {
        PermissionStatusSnapshot(
            microphone: microphonePermissionProvider.currentStatus(),
            speechRecognition: speechRecognitionPermissionProvider.currentStatus(),
            accessibility: accessibilityPermissionProvider.currentStatus()
        )
    }
}

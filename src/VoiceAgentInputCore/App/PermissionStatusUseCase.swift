import Foundation

public struct PermissionStatusSnapshot: Equatable, Sendable {
    public var microphone: MicrophonePermissionStatus
    public var speechRecognition: SpeechRecognitionPermissionStatus
    public var accessibility: AccessibilityPermissionStatus
    public var inputMonitoring: InputMonitoringPermissionStatus

    public init(
        microphone: MicrophonePermissionStatus,
        speechRecognition: SpeechRecognitionPermissionStatus,
        accessibility: AccessibilityPermissionStatus,
        inputMonitoring: InputMonitoringPermissionStatus = .notTrusted
    ) {
        self.microphone = microphone
        self.speechRecognition = speechRecognition
        self.accessibility = accessibility
        self.inputMonitoring = inputMonitoring
    }
}

public struct PermissionStatusUseCase {
    public var microphonePermissionProvider: any MicrophonePermissionProvider
    public var speechRecognitionPermissionProvider: any SpeechRecognitionPermissionProvider
    public var accessibilityPermissionProvider: any AccessibilityPermissionProvider
    public var inputMonitoringPermissionProvider: any InputMonitoringPermissionProvider

    public init(
        microphonePermissionProvider: any MicrophonePermissionProvider,
        speechRecognitionPermissionProvider: any SpeechRecognitionPermissionProvider,
        accessibilityPermissionProvider: any AccessibilityPermissionProvider,
        inputMonitoringPermissionProvider: any InputMonitoringPermissionProvider = MockInputMonitoringPermissionProvider(status: .notTrusted)
    ) {
        self.microphonePermissionProvider = microphonePermissionProvider
        self.speechRecognitionPermissionProvider = speechRecognitionPermissionProvider
        self.accessibilityPermissionProvider = accessibilityPermissionProvider
        self.inputMonitoringPermissionProvider = inputMonitoringPermissionProvider
    }

    public func currentStatus() -> PermissionStatusSnapshot {
        PermissionStatusSnapshot(
            microphone: microphonePermissionProvider.currentStatus(),
            speechRecognition: speechRecognitionPermissionProvider.currentStatus(),
            accessibility: accessibilityPermissionProvider.currentStatus(),
            inputMonitoring: inputMonitoringPermissionProvider.currentStatus()
        )
    }
}

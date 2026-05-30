import Foundation

public final class MockSpeechRecognitionPermissionProvider: SpeechRecognitionPermissionProvider {
    public var status: SpeechRecognitionPermissionStatus
    public var requestedStatus: SpeechRecognitionPermissionStatus
    public private(set) var requestAccessCallCount = 0

    public init(status: SpeechRecognitionPermissionStatus, requestedStatus: SpeechRecognitionPermissionStatus? = nil) {
        self.status = status
        self.requestedStatus = requestedStatus ?? status
    }

    public func currentStatus() -> SpeechRecognitionPermissionStatus {
        status
    }

    public func requestAccess() async -> SpeechRecognitionPermissionStatus {
        requestAccessCallCount += 1
        status = requestedStatus
        return status
    }
}

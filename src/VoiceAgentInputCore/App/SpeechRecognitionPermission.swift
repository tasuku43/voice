import Foundation

public enum SpeechRecognitionPermissionStatus: String, Equatable, Sendable {
    case authorized
    case denied
    case notDetermined
    case restricted
    case unknown
}

public protocol SpeechRecognitionPermissionProvider {
    func currentStatus() -> SpeechRecognitionPermissionStatus
    func requestAccess() async -> SpeechRecognitionPermissionStatus
}

public struct SpeechRecognitionPermissionUseCase {
    public var provider: any SpeechRecognitionPermissionProvider

    public init(provider: any SpeechRecognitionPermissionProvider) {
        self.provider = provider
    }

    @discardableResult
    public func ensureTranscriptionAllowed() async throws -> SpeechRecognitionPermissionStatus {
        let status = provider.currentStatus()
        if status == .authorized {
            return status
        }

        if status == .notDetermined {
            let requestedStatus = await provider.requestAccess()
            guard requestedStatus == .authorized else {
                throw SpeechRecognitionPermissionError.transcriptionNotAllowed(status: requestedStatus)
            }
            return requestedStatus
        }

        throw SpeechRecognitionPermissionError.transcriptionNotAllowed(status: status)
    }
}

public enum SpeechRecognitionPermissionError: Error, Equatable {
    case transcriptionNotAllowed(status: SpeechRecognitionPermissionStatus)
}

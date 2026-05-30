import Foundation

public protocol AudioRecorder {
    func recordOnce() async throws -> RecordedAudio
}

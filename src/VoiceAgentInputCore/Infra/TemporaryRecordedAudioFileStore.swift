import Foundation

public struct TemporaryRecordedAudioFileStore: Sendable {
    public var directoryURL: URL

    public init(directoryURL: URL = FileManager.default.temporaryDirectory) {
        self.directoryURL = directoryURL
    }

    public func withRecordedAudioFile<T>(
        _ audio: RecordedAudio,
        operation: (URL) async throws -> T
    ) async throws -> T {
        let url = directoryURL
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")
        try audio.data.write(to: url, options: .atomic)
        defer {
            try? FileManager.default.removeItem(at: url)
        }
        return try await operation(url)
    }
}

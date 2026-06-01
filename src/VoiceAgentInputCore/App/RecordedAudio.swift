import Foundation

public struct RecordedAudio: Equatable, Sendable {
    public var data: Data
    public var temporaryFileURL: URL?
    public var shouldDeleteTemporaryFile: Bool
    public var formatDescription: String
    public var durationSeconds: Double
    public var byteCount: Int

    public init(
        data: Data,
        formatDescription: String,
        durationSeconds: Double,
        temporaryFileURL: URL? = nil,
        shouldDeleteTemporaryFile: Bool = false,
        byteCount: Int? = nil
    ) {
        self.data = data
        self.temporaryFileURL = temporaryFileURL
        self.shouldDeleteTemporaryFile = shouldDeleteTemporaryFile
        self.formatDescription = formatDescription
        self.durationSeconds = durationSeconds
        self.byteCount = byteCount ?? data.count
    }
}

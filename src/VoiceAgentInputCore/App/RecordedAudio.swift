import Foundation

public struct RecordedAudio: Equatable, Sendable {
    public var data: Data
    public var formatDescription: String
    public var durationSeconds: Double

    public init(data: Data, formatDescription: String, durationSeconds: Double) {
        self.data = data
        self.formatDescription = formatDescription
        self.durationSeconds = durationSeconds
    }
}

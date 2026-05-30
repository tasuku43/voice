import Foundation

public struct Transcript: Equatable, Sendable {
    public var text: String
    public var localeIdentifier: String?
    public var confidence: Double?

    public init(text: String, localeIdentifier: String? = nil, confidence: Double? = nil) {
        self.text = text
        self.localeIdentifier = localeIdentifier
        self.confidence = confidence
    }
}

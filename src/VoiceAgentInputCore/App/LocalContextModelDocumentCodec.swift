import Foundation

public struct LocalContextModelDocument: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var model: LocalContextModel

    public init(schemaVersion: Int = 1, model: LocalContextModel) {
        self.schemaVersion = schemaVersion
        self.model = model
    }
}

public struct LocalContextModelDocumentCodec: Sendable {
    public init() {}

    public func encode(_ model: LocalContextModel) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(LocalContextModelDocument(model: model))
    }

    public func decode(_ data: Data) throws -> LocalContextModel {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(LocalContextModelDocument.self, from: data).model
    }
}

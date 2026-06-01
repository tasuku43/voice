import Foundation

public struct JSONLocalContextModelRepository: LocalContextModelRepository {
    public var fileURL: URL
    public var codec: LocalContextModelDocumentCodec

    public init(
        fileURL: URL,
        codec: LocalContextModelDocumentCodec = LocalContextModelDocumentCodec()
    ) {
        self.fileURL = fileURL
        self.codec = codec
    }

    public func loadModel() throws -> LocalContextModel {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return LocalContextModel()
        }
        return try codec.decode(Data(contentsOf: fileURL))
    }

    public func saveModel(_ model: LocalContextModel) throws {
        let data = try codec.encode(model)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: [.atomic])
    }
}

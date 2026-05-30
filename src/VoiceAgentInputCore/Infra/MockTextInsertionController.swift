import Foundation

public final class MockTextInsertionController: TextInsertionController {
    public private(set) var insertedRequests: [TextInsertionRequest]

    public init(insertedRequests: [TextInsertionRequest] = []) {
        self.insertedRequests = insertedRequests
    }

    public func insert(_ request: TextInsertionRequest) throws {
        insertedRequests.append(request)
    }
}

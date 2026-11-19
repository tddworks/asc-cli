import Foundation
@testable import ASCKit

final class StubHTTPClient: HTTPPerforming, @unchecked Sendable {
    var response: (Data, URLResponse)?
    var error: Error?
    private(set) var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let error { throw error }
        return response!
    }
}

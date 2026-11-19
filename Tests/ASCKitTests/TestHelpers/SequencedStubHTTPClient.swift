import Foundation
@testable import ASCKit

final class SequencedStubHTTPClient: HTTPPerforming, @unchecked Sendable {
    private var queue: [Result<(Data, URLResponse), Error>] = []
    private(set) var capturedRequests: [URLRequest] = []

    func enqueue(json: String, statusCode: Int = 200, url: String = "https://api.github.com") {
        let urlResponse = HTTPURLResponse(
            url: URL(string: url)!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        queue.append(.success((Data(json.utf8), urlResponse)))
    }

    func enqueueError(_ error: Error) {
        queue.append(.failure(error))
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequests.append(request)
        guard !queue.isEmpty else {
            fatalError("SequencedStubHTTPClient: empty queue for \(request.url?.absoluteString ?? "?")")
        }
        switch queue.removeFirst() {
        case .success(let pair): return pair
        case .failure(let e): throw e
        }
    }
}

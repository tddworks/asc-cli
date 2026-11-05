@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
@testable import Infrastructure

/// Throwing error used by `StubAPIClient` when no stub matches the requested response type.
/// Adapters that tolerate ASC 404s (like `getAvailability` for new IAPs) can be tested by
/// simply not stubbing — the request throws and the adapter's `catch` returns nil.
struct StubAPIClientError: Error {
    let message: String
}

final class StubAPIClient: APIClient, @unchecked Sendable {
    /// Per-type stubs keyed by `String(describing: T.self)`. Lookup falls back to the
    /// last `willReturn(_:)` value if no type-specific stub matches — keeping older
    /// single-stub call sites working while enabling multi-call adapters.
    private var stubsByType: [String: Any] = [:]
    private var lastStub: Any?
    private(set) var voidRequestCalled = false
    private(set) var lastQuery: [(String, String?)]?
    private(set) var lastPath: String?
    /// Every request sent, in order — lets multi-call adapters assert what went over the wire.
    private(set) var requests: [RecordedRequest] = []
    /// Queued responses served one per call before falling back to `stubsByType` (pagination).
    private var pagesByType: [String: [Any]] = [:]

    struct RecordedRequest {
        let method: String
        let path: String
        let query: [(String, String?)]?
        /// JSON-encoded request body, `nil` for body-less requests.
        let body: String?
    }

    /// When set, every request throws this error (simulates an ASC failure response).
    var errorToThrow: (any Error)?
    /// Throws only for the request with this method and path, e.g. "POST /v1/reviewSubmissionItems".
    var errorsByRequest: [String: any Error] = [:]

    func willReturn<T>(_ response: T) {
        stubsByType[String(describing: T.self)] = response
        lastStub = response
    }

    /// Serves `pages` in order for successive requests returning `T`.
    func willReturnPages<T>(_ pages: [T]) {
        pagesByType[String(describing: T.self), default: []].append(contentsOf: pages.map { $0 as Any })
    }

    func request<T: Decodable>(_ endpoint: Request<T>) async throws -> T {
        lastQuery = endpoint.query
        lastPath = endpoint.path
        requests.append(RecordedRequest(
            method: endpoint.method, path: endpoint.path, query: endpoint.query, body: Self.encodedBody(of: endpoint)
        ))
        if let errorToThrow { throw errorToThrow }
        if let error = errorsByRequest["\(endpoint.method) \(endpoint.path)"] { throw error }
        let key = String(describing: T.self)
        if var pages = pagesByType[key], !pages.isEmpty, let page = pages.removeFirst() as? T {
            pagesByType[key] = pages
            return page
        }
        if let response = stubsByType[key] as? T { return response }
        if let response = lastStub as? T { return response }
        // Throw rather than fatalError so adapters can simulate ASC 404 by simply not stubbing.
        throw StubAPIClientError(message: "no stub configured for \(T.self)")
    }

    func request(_ endpoint: Request<Void>) async throws {
        voidRequestCalled = true
        requests.append(RecordedRequest(
            method: endpoint.method, path: endpoint.path, query: endpoint.query, body: Self.encodedBody(of: endpoint)
        ))
    }

    /// `Request.body` is internal to the SDK, so read it reflectively and JSON-encode it.
    private static func encodedBody<T>(of endpoint: Request<T>) -> String? {
        guard let optional = Mirror(reflecting: endpoint).children.first(where: { $0.label == "body" })?.value,
              let body = Mirror(reflecting: optional).children.first?.value as? any Encodable
        else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return (try? encoder.encode(body)).flatMap { String(data: $0, encoding: .utf8) }
    }
}

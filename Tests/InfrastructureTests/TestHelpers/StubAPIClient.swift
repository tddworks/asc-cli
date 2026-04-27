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

    func willReturn<T>(_ response: T) {
        stubsByType[String(describing: T.self)] = response
        lastStub = response
    }

    func request<T: Decodable>(_ endpoint: Request<T>) async throws -> T {
        let key = String(describing: T.self)
        if let response = stubsByType[key] as? T { return response }
        if let response = lastStub as? T { return response }
        // Throw rather than fatalError so adapters can simulate ASC 404 by simply not stubbing.
        throw StubAPIClientError(message: "no stub configured for \(T.self)")
    }

    func request(_ endpoint: Request<Void>) async throws {
        voidRequestCalled = true
    }
}

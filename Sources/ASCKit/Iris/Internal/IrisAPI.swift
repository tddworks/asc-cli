import Foundation
import Mockable

/// The iris private API (`appstoreconnect.apple.com/iris/v1`), as the iris
/// repositories use it. `IrisClient` plays it over HTTP.
@Mockable
public protocol IrisAPI: Sendable {
    func get(path: String, queryItems: [URLQueryItem], cookies: String) async throws -> (Data, HTTPURLResponse)
    func post(path: String, body: Data, cookies: String) async throws -> (Data, HTTPURLResponse)
    /// Fetch an absolute URL with the session cookies. Callers validate the host first.
    func download(absoluteURL: URL, cookies: String) async throws -> (Data, HTTPURLResponse)
    func delete(path: String, cookies: String) async throws -> (Data, HTTPURLResponse)
}

extension IrisAPI {
    func get(path: String, cookies: String) async throws -> (Data, HTTPURLResponse) {
        try await get(path: path, queryItems: [], cookies: cookies)
    }
}

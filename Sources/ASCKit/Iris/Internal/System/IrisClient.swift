import Foundation

/// HTTP client for the iris private API. Only the `URLSession` call lives here;
/// the request is `IrisRequest`'s and what the reply means is `IrisResponse`'s.
public struct IrisClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(path: String, queryItems: [URLQueryItem] = [], cookies: String) async throws -> (Data, HTTPURLResponse) {
        try await perform(IrisRequest.get(path: path, queryItems: queryItems, cookies: cookies))
    }

    public func post(path: String, body: Data, cookies: String) async throws -> (Data, HTTPURLResponse) {
        try await perform(IrisRequest.post(path: path, body: body, cookies: cookies))
    }

    /// Fetch an absolute URL with the session cookies. Callers validate the host first.
    public func download(absoluteURL: URL, cookies: String) async throws -> (Data, HTTPURLResponse) {
        try await perform(IrisRequest.download(absoluteURL: absoluteURL, cookies: cookies))
    }

    /// Used by the iris-only IAP submission dequeue (`DELETE /iris/v1/inAppPurchaseSubmissions/:id`).
    public func delete(path: String, cookies: String) async throws -> (Data, HTTPURLResponse) {
        try await perform(IrisRequest.delete(path: path, cookies: cookies))
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        return try IrisResponse.accepted(data: data, response: response)
    }
}

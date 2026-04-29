import Domain
import Foundation

/// Generic HTTP client for the iris private API.
///
/// Handles cookie injection, required headers, and JSON:API
/// request/response encoding for `appstoreconnect.apple.com/iris/v1/`.
public struct IrisClient: Sendable {
    private static let baseURL = "https://appstoreconnect.apple.com/iris/v1"

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Perform a GET request against the iris API.
    public func get(
        path: String,
        queryItems: [URLQueryItem] = [],
        cookies: String
    ) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(string: "\(Self.baseURL)/\(path)")!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        applyHeaders(to: &request, cookies: cookies)
        return try await perform(request)
    }

    /// Perform a POST request against the iris API.
    public func post(
        path: String,
        body: Data,
        cookies: String
    ) async throws -> (Data, HTTPURLResponse) {
        let url = URL(string: "\(Self.baseURL)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        applyHeaders(to: &request, cookies: cookies)
        return try await perform(request)
    }

    /// Perform a DELETE request against the iris API. Used by the iris-only
    /// IAP submission dequeue (`DELETE /iris/v1/inAppPurchaseSubmissions/:id`),
    /// which the public ASC SDK can't call (different auth surface).
    public func delete(
        path: String,
        cookies: String
    ) async throws -> (Data, HTTPURLResponse) {
        let url = URL(string: "\(Self.baseURL)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyHeaders(to: &request, cookies: cookies)
        return try await perform(request)
    }

    private func applyHeaders(to request: inout URLRequest, cookies: String) {
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "accept")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "content-type")
        request.setValue(cookies, forHTTPHeaderField: "cookie")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
            forHTTPHeaderField: "user-agent"
        )
        request.setValue("[asc-ui]", forHTTPHeaderField: "x-csrf-itc")
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IrisAPIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw IrisAPIError.httpError(
                statusCode: httpResponse.statusCode,
                body: String(data: data, encoding: .utf8)
            )
        }
        return (data, httpResponse)
    }
}

/// Errors from the iris HTTP layer.
public enum IrisAPIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, body: String?)
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Invalid response from iris API"
        case .httpError(let statusCode, let body):
            "Iris API error \(statusCode): \(body ?? "no body")"
        case .decodingError(let detail):
            "Failed to decode iris response: \(detail)"
        }
    }
}

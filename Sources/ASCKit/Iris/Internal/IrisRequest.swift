import Foundation

/// The requests the iris private API accepts: `appstoreconnect.apple.com/iris/v1/<path>`,
/// JSON:API, the session cookies, and the headers the web UI sends.
enum IrisRequest {
    static let baseURL = "https://appstoreconnect.apple.com/iris/v1"
    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"

    static func get(path: String, queryItems: [URLQueryItem], cookies: String) -> URLRequest {
        var components = URLComponents(string: "\(baseURL)/\(path)")!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return iris(url: components.url!, method: "GET", cookies: cookies)
    }

    static func post(path: String, body: Data, cookies: String) -> URLRequest {
        var request = iris(url: URL(string: "\(baseURL)/\(path)")!, method: "POST", cookies: cookies)
        request.httpBody = body
        return request
    }

    static func patch(path: String, body: Data, cookies: String) -> URLRequest {
        var request = iris(url: URL(string: "\(baseURL)/\(path)")!, method: "PATCH", cookies: cookies)
        request.httpBody = body
        return request
    }

    static func delete(path: String, cookies: String) -> URLRequest {
        iris(url: URL(string: "\(baseURL)/\(path)")!, method: "DELETE", cookies: cookies)
    }

    /// An absolute URL (e.g. an Apple-signed attachment) with only the session cookies.
    /// Callers validate the host first: this fetches whatever it is given.
    static func download(absoluteURL: URL, cookies: String) -> URLRequest {
        var request = URLRequest(url: absoluteURL)
        request.httpMethod = "GET"
        request.setValue(cookies, forHTTPHeaderField: "cookie")
        return request
    }

    static let complianceBaseURL = "https://appstoreconnect.apple.com/ppm/compliancerequirements/v1"

    /// A request to the App Compliance service (`ppm/compliancerequirements/v1`): plain JSON,
    /// the same session cookies and browser headers as iris.
    static func compliance(method: String, path: String, queryItems: [URLQueryItem], body: Data?, cookies: String) -> URLRequest {
        var components = URLComponents(string: "\(complianceBaseURL)/\(path)")!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(cookies, forHTTPHeaderField: "cookie")
        request.setValue(userAgent, forHTTPHeaderField: "user-agent")
        request.setValue("[asc-ui]", forHTTPHeaderField: "x-csrf-itc")
        return request
    }

    private static func iris(url: URL, method: String, cookies: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "accept")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "content-type")
        request.setValue(cookies, forHTTPHeaderField: "cookie")
        request.setValue(userAgent, forHTTPHeaderField: "user-agent")
        request.setValue("[asc-ui]", forHTTPHeaderField: "x-csrf-itc")
        return request
    }
}

/// What iris's reply means: the body on a 2xx, `IrisAPIError` otherwise.
enum IrisResponse {
    static func accepted(data: Data, response: URLResponse) throws -> (Data, HTTPURLResponse) {
        guard let http = response as? HTTPURLResponse else {
            throw IrisAPIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw IrisAPIError.httpError(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
        }
        return (data, http)
    }
}

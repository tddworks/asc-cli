public enum APIError: Error, Equatable, Sendable {
    case unauthorized
    case forbidden
    case notFound(String)
    case rateLimited
    case serverError(Int)
    case networkError(String)
    case decodingError(String)
    case unknown(String)
}

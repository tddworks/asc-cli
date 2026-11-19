import Foundation

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

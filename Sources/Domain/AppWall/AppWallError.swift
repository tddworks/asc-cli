import Foundation

public enum AppWallError: Error, LocalizedError, Equatable {
    case alreadySubmitted(developer: String)
    case forkTimeout
    case githubAPIError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .alreadySubmitted(let developer):
            return "Developer \(developer) is already listed in the app wall."
        case .forkTimeout:
            return "Timed out waiting for fork to be ready. Please try again in a moment."
        case .githubAPIError(let statusCode, let message):
            return "GitHub API error (\(statusCode)): \(message)"
        }
    }
}

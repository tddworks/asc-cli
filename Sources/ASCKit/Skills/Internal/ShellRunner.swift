import Foundation

/// Abstraction for executing shell commands, enabling testability.
public protocol ShellRunner: Sendable {
    func run(command: String, arguments: [String], environment: [String: String]?) async throws -> String
}

public enum ShellRunnerError: Error, LocalizedError {
    case commandNotFound
    case executionFailed(exitCode: Int32, stderr: String)

    public var errorDescription: String? {
        switch self {
        case .commandNotFound:
            return "Command not found"
        case .executionFailed(let code, let stderr):
            return "Command exited with code \(code): \(stderr)"
        }
    }
}

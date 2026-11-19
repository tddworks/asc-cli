import Foundation

public enum ComplianceError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    /// Refused by the requirement itself, before anything reaches Apple (law 5).
    case notDeclarable(kind: ComplianceKind, status: ComplianceStatus)

    public var description: String {
        switch self {
        case .notDeclarable(let kind, _) where !kind.isRecognized:
            "\(kind.displayName) is a compliance asc doesn't know yet, so it can't declare it. Answer it on the App Compliance page."
        case .notDeclarable(let kind, let status):
            "\(kind.displayName) can't be changed while it is \(status.displayName): Apple is checking the last answer."
        }
    }

    public var errorDescription: String? { description }
}

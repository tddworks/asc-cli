import Foundation

public enum ComplianceError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    /// Refused by the requirement itself, before anything reaches Apple (law 5).
    case notDeclarable(kind: ComplianceKind, status: ComplianceStatus)
    /// The session doesn't say which team it belongs to (olympus gave no `publicProviderId`).
    case teamUnknown
    /// Apple serves the form without `editable` (law 5a): nothing was saved.
    case readOnly(kind: ComplianceKind)
    /// Apple forbade the save (403): the signed-in role can't edit App Compliance.
    case roleCannotEdit(appId: String)

    public var description: String {
        switch self {
        case .notDeclarable(let kind, _) where !kind.isRecognized:
            "\(kind.displayName) is a compliance asc doesn't know yet, so it can't declare it. Answer it on the App Compliance page."
        case .notDeclarable(let kind, let status):
            "\(kind.displayName) can't be changed while it is \(status.displayName): Apple is checking the last answer."
        case .readOnly(let kind):
            "Apple won't take a change to \(kind.displayName) right now: the App Compliance page shows it read-only."
        case .roleCannotEdit(let appId):
            "Your App Store Connect role can't edit App Compliance for app \(appId). Ask your Account Holder or an Admin."
        case .teamUnknown:
            "Couldn't tell which team this App Store Connect session belongs to. Sign in again with `asc iris auth login`."
        }
    }

    public var errorDescription: String? { description }
}

import Foundation

public enum ComplianceError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    /// Refused by the requirement itself, before anything reaches Apple (law 5).
    case notDeclarable(kind: ComplianceKind, status: ComplianceStatus)
    /// The session doesn't say which team it belongs to (olympus gave no `publicProviderId`).
    case teamUnknown
    /// A file whose extension the field doesn't accept (law 9).
    case fileTypeNotAllowed(fileName: String, allowed: [String])
    /// Apple's form asks for a field asc can't fill from the answer: nothing was saved.
    case formNotUnderstood(kind: ComplianceKind, field: String)
    /// A Yes without all of its kind's evidence (law 3).
    case evidenceMissing(kind: ComplianceKind, missing: [String])
    /// A Yes whose evidence belongs to another compliance.
    case evidenceMismatch(kind: ComplianceKind)
    /// No row with this requirement id on this app (a requirement is addressed by both, law 2).
    case requirementNotFound(requirementId: String, appId: String)
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
        case .requirementNotFound(let requirementId, let appId):
            "App \(appId) has no compliance requirement \(requirementId). See `asc iris app-compliance list --app-id \(appId)`."
        case .evidenceMissing(let kind, let missing):
            "A Yes to \(kind.displayName) needs \(missing.joined(separator: " and "))."
        case .evidenceMismatch(let kind):
            "That evidence isn't for \(kind.displayName); answer it with \(kind.displayName)'s own."
        case .fileTypeNotAllowed(let fileName, let allowed):
            "\(fileName) can't be sent: this field takes \(allowed.joined(separator: ", "))."
        case .formNotUnderstood(let kind, let field):
            "Apple's \(kind.displayName) form asks for something asc doesn't know (\(field)). Answer it on the App Compliance page."
        case .teamUnknown:
            "Couldn't tell which team this App Store Connect session belongs to. Sign in again with `asc iris auth login`."
        }
    }

    public var errorDescription: String? { description }
}

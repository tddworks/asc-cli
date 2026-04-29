import Foundation

/// Compact, non-secret view of an `IrisAuthSession` for command output. We never
/// expose cookies / scnt / serviceKey through the formatter — they're sensitive
/// material; only metadata fit for stdout lands here.
public struct IrisAuthSummary: Sendable, Equatable, Codable, Identifiable {
    public let id: String                  // userEmail (acts as account id for table view)
    public let userEmail: String
    public let providerID: Int64?
    public let teamId: String?
    public let expiresAt: Date

    public init(
        userEmail: String,
        providerID: Int64?,
        teamId: String?,
        expiresAt: Date
    ) {
        self.id = userEmail
        self.userEmail = userEmail
        self.providerID = providerID
        self.teamId = teamId
        self.expiresAt = expiresAt
    }

    public init(_ session: IrisAuthSession) {
        self.init(
            userEmail: session.userEmail,
            providerID: session.providerID,
            teamId: session.teamId,
            expiresAt: session.expiresAt
        )
    }
}

extension IrisAuthSummary: Presentable {
    public static var tableHeaders: [String] { ["Email", "Provider", "Team", "Expires"] }
    public var tableRow: [String] {
        let formatter = ISO8601DateFormatter()
        return [
            userEmail,
            providerID.map { "\($0)" } ?? "",
            teamId ?? "",
            formatter.string(from: expiresAt),
        ]
    }
}

extension IrisAuthSummary: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "logout": "asc iris auth logout",
            "status": "asc iris status",
        ]
    }
}

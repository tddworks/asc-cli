import Foundation

/// The artifact a successful iris login produces.
///
/// `cookies` is what `IrisClient` actually consumes for subsequent calls. The other
/// fields (`scnt`, `serviceKey`, `appleIDSessionID`) let us re-attempt 2FA or trust
/// without restarting the flow from scratch. `providerID` / `teamId` / `userEmail`
/// come from the post-login `olympus/v1/session` call and are useful UX signals
/// (e.g. "logged in as Acme LLC, providerID 12345"). `expiresAt` is a best-guess
/// from cookie max-age; iris doesn't expose a refresh contract.
public struct IrisAuthSession: Sendable, Equatable {
    public let cookies: String
    public let scnt: String
    public let serviceKey: String
    public let appleIDSessionID: String
    public let providerID: Int64?
    public let teamId: String?
    public let userEmail: String
    public let expiresAt: Date

    public init(
        cookies: String,
        scnt: String,
        serviceKey: String,
        appleIDSessionID: String,
        providerID: Int64? = nil,
        teamId: String? = nil,
        userEmail: String,
        expiresAt: Date
    ) {
        self.cookies = cookies
        self.scnt = scnt
        self.serviceKey = serviceKey
        self.appleIDSessionID = appleIDSessionID
        self.providerID = providerID
        self.teamId = teamId
        self.userEmail = userEmail
        self.expiresAt = expiresAt
    }
}

extension IrisAuthSession: Codable {
    enum CodingKeys: String, CodingKey {
        case cookies, scnt, serviceKey, appleIDSessionID, providerID, teamId, userEmail, expiresAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cookies = try c.decode(String.self, forKey: .cookies)
        scnt = try c.decode(String.self, forKey: .scnt)
        serviceKey = try c.decode(String.self, forKey: .serviceKey)
        appleIDSessionID = try c.decode(String.self, forKey: .appleIDSessionID)
        providerID = try c.decodeIfPresent(Int64.self, forKey: .providerID)
        teamId = try c.decodeIfPresent(String.self, forKey: .teamId)
        userEmail = try c.decode(String.self, forKey: .userEmail)
        expiresAt = try c.decode(Date.self, forKey: .expiresAt)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(cookies, forKey: .cookies)
        try c.encode(scnt, forKey: .scnt)
        try c.encode(serviceKey, forKey: .serviceKey)
        try c.encode(appleIDSessionID, forKey: .appleIDSessionID)
        try c.encodeIfPresent(providerID, forKey: .providerID)
        try c.encodeIfPresent(teamId, forKey: .teamId)
        try c.encode(userEmail, forKey: .userEmail)
        try c.encode(expiresAt, forKey: .expiresAt)
    }
}

/// Status of the iris cookie-based session.
public struct IrisStatus: Sendable, Equatable, Codable {
    public let source: IrisCookieSource
    public let cookieCount: Int

    public init(source: IrisCookieSource, cookieCount: Int) {
        self.source = source
        self.cookieCount = cookieCount
    }
}

/// Where the iris cookies were resolved from.
public enum IrisCookieSource: String, Sendable, Equatable, Codable {
    case browser
    case environment
    /// Session persisted by `asc iris auth login` (Apple SRP login).
    case srpLogin
}

extension IrisStatus: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listApps": "asc iris apps list",
            "createApp": "asc iris apps create --name <name> --bundle-id <id> --sku <sku>",
            "submitIAP": "asc iris iap-submissions create --iap-id <iap-id>",
        ]
    }
}

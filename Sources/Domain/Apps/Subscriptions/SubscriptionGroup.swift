public struct SubscriptionGroup: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure since ASC API omits it from response
    public let appId: String
    public let referenceName: String

    public init(id: String, appId: String, referenceName: String) {
        self.id = id
        self.appId = appId
        self.referenceName = referenceName
    }
}

extension SubscriptionGroup: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Reference Name"]
    }
    public var tableRow: [String] {
        [id, referenceName]
    }
}

extension SubscriptionGroup: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "createLocalization": "asc subscription-group-localizations create --group-id \(id) --locale en-US --name <name>",
            "createSubscription": "asc subscriptions create --group-id \(id) --name <name> --product-id <id> --period ONE_MONTH",
            "delete": "asc subscription-groups delete --group-id \(id)",
            "listLocalizations": "asc subscription-group-localizations list --group-id \(id)",
            "listSubscriptions": "asc subscriptions list --group-id \(id)",
            "update": "asc subscription-groups update --group-id \(id) --reference-name <name>",
        ]
    }
}

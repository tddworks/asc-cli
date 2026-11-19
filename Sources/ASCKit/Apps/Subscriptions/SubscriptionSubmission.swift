public struct SubscriptionSubmission: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure since ASC API omits it from response
    public let subscriptionId: String

    public init(id: String, subscriptionId: String) {
        self.id = id
        self.subscriptionId = subscriptionId
    }
}

extension SubscriptionSubmission: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listLocalizations": "asc subscription-localizations list --subscription-id \(subscriptionId)",
            "unsubmit": "asc subscriptions unsubmit --submission-id \(id)",
        ]
    }
}

extension SubscriptionSubmission: Presentable {
    public static var tableHeaders: [String] { ["ID", "Subscription ID"] }
    public var tableRow: [String] { [id, subscriptionId] }
}

public struct InAppPurchaseSubmission: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure since ASC API omits it from response
    public let iapId: String

    public init(id: String, iapId: String) {
        self.id = id
        self.iapId = iapId
    }
}

extension InAppPurchaseSubmission: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listLocalizations": "asc iap-localizations list --iap-id \(iapId)",
            "unsubmit": "asc iap unsubmit --submission-id \(id)",
        ]
    }
}

extension InAppPurchaseSubmission: Presentable {
    public static var tableHeaders: [String] { ["ID", "IAP ID"] }
    public var tableRow: [String] { [id, iapId] }
}

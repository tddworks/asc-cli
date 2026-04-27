public struct InAppPurchasePriceSchedule: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure
    public let iapId: String

    public init(id: String, iapId: String) {
        self.id = id
        self.iapId = iapId
    }
}

extension InAppPurchasePriceSchedule: Presentable {
    public static var tableHeaders: [String] { ["ID", "IAP ID"] }
    public var tableRow: [String] { [id, iapId] }
}

extension InAppPurchasePriceSchedule: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listPricePoints", command: "iap price-points", action: "list", params: ["iap-id": iapId]),
            Affordance(key: "getIAP", command: "iap", action: "get", params: ["iap-id": iapId]),
        ]
    }
}

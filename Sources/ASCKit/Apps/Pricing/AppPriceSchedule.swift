/// An app's price schedule: the base-territory price Apple equalizes worldwide.
public struct AppPriceSchedule: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app — injected by Infrastructure.
    public let appId: String
    public let baseTerritory: String

    public init(id: String, appId: String, baseTerritory: String) {
        self.id = id
        self.appId = appId
        self.baseTerritory = baseTerritory
    }
}

extension AppPriceSchedule: Presentable {
    public static var tableHeaders: [String] { ["ID", "App ID", "Base Territory"] }
    public var tableRow: [String] { [id, appId, baseTerritory] }
}

extension AppPriceSchedule: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [Affordance(key: "listPricePoints", command: "apps price-points", action: "list",
                    params: ["app-id": appId, "territory": baseTerritory])]
    }
}

public struct AppAvailability: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure since ASC API omits it from response
    public let appId: String
    public let isAvailableInNewTerritories: Bool
    public let territories: [AppTerritoryAvailability]

    public init(
        id: String,
        appId: String,
        isAvailableInNewTerritories: Bool,
        territories: [AppTerritoryAvailability]
    ) {
        self.id = id
        self.appId = appId
        self.isAvailableInNewTerritories = isAvailableInNewTerritories
        self.territories = territories
    }
}

extension AppAvailability: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "getAvailability", command: "app-availability", action: "get", params: ["app-id": appId]),
            Affordance(key: "listTerritories", command: "territories", action: "list"),
        ]
    }
}

extension AppAvailability: Presentable {
    public static var tableHeaders: [String] { ["ID", "App ID", "Available in New Territories", "Territories"] }
    public var tableRow: [String] {
        [id, appId, String(isAvailableInNewTerritories), "\(territories.filter(\.isAvailable).count)/\(territories.count) available"]
    }
}

extension RESTPathResolver {
    static let _appAvailabilityRoutes: Void = {
        registerRoute(command: "app-availability", parentParam: "app-id", parentSegment: "apps", segment: "availability")
    }()
}

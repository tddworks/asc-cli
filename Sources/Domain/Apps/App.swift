public struct App: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let bundleId: String
    public let sku: String?
    public let primaryLocale: String?

    public init(
        id: String,
        name: String,
        bundleId: String,
        sku: String? = nil,
        primaryLocale: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.sku = sku
        self.primaryLocale = primaryLocale
    }

    public var displayName: String {
        name.isEmpty ? bundleId : name
    }
}

extension App: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Bundle ID", "SKU"]
    }
    public var tableRow: [String] {
        [id, displayName, bundleId, sku ?? "-"]
    }
}

extension App: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": id]),
            Affordance(key: "listAppInfos", command: "app-infos", action: "list", params: ["app-id": id]),
            Affordance(key: "listReviews", command: "reviews", action: "list", params: ["app-id": id]),
        ]
    }

    public var registryProperties: [String: String] {
        ["name": name]
    }
}

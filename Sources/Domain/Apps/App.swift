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

extension App: AffordanceProviding {
    public var affordances: [String: String] {
        ["listVersions": "asc versions list --app-id \(id)"]
    }
}

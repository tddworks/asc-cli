public enum ContentRightsDeclaration: String, Sendable, Equatable, Codable, CaseIterable {
    case usesThirdPartyContent = "USES_THIRD_PARTY_CONTENT"
    case doesNotUseThirdPartyContent = "DOES_NOT_USE_THIRD_PARTY_CONTENT"
}

public struct App: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let bundleId: String
    public let sku: String?
    public let primaryLocale: String?
    public let iconAsset: ImageAsset?
    public let contentRightsDeclaration: ContentRightsDeclaration?

    public init(
        id: String,
        name: String,
        bundleId: String,
        sku: String? = nil,
        primaryLocale: String? = nil,
        iconAsset: ImageAsset? = nil,
        contentRightsDeclaration: ContentRightsDeclaration? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.sku = sku
        self.primaryLocale = primaryLocale
        self.iconAsset = iconAsset
        self.contentRightsDeclaration = contentRightsDeclaration
    }

    public var displayName: String {
        name.isEmpty ? bundleId : name
    }

    public func with(iconAsset: ImageAsset?) -> App {
        App(
            id: id,
            name: name,
            bundleId: bundleId,
            sku: sku,
            primaryLocale: primaryLocale,
            iconAsset: iconAsset,
            contentRightsDeclaration: contentRightsDeclaration
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, bundleId, sku, primaryLocale, iconAsset, contentRightsDeclaration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(bundleId, forKey: .bundleId)
        try container.encodeIfPresent(sku, forKey: .sku)
        try container.encodeIfPresent(primaryLocale, forKey: .primaryLocale)
        try container.encodeIfPresent(iconAsset, forKey: .iconAsset)
        try container.encodeIfPresent(contentRightsDeclaration, forKey: .contentRightsDeclaration)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.bundleId = try container.decode(String.self, forKey: .bundleId)
        self.sku = try container.decodeIfPresent(String.self, forKey: .sku)
        self.primaryLocale = try container.decodeIfPresent(String.self, forKey: .primaryLocale)
        self.iconAsset = try container.decodeIfPresent(ImageAsset.self, forKey: .iconAsset)
        self.contentRightsDeclaration = try container.decodeIfPresent(ContentRightsDeclaration.self, forKey: .contentRightsDeclaration)
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
            Affordance(key: "createVersion", command: "versions", action: "create", params: ["app-id": id]),
            Affordance(key: "listAppInfos", command: "app-infos", action: "list", params: ["app-id": id]),
            Affordance(key: "listReviews", command: "reviews", action: "list", params: ["app-id": id]),
            Affordance(key: "updateContentRights", command: "apps", action: "update", params: ["app-id": id]),
        ]
    }

    public var registryProperties: [String: String] {
        ["name": name]
    }
}

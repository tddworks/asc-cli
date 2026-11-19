/// One placement group of one placement type, flattened from App Store Connect's reference
/// data (`appAssetLibraryRefData`). Group identifiers, platforms and display classes stay
/// strings: Apple adds device families without an API change.
public struct AssetPlacementGroup: Sendable, Equatable, Identifiable {
    /// The placement group identifier, e.g. `IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE`.
    public let id: String
    public let placementType: AssetPlacementType
    public let platform: String?
    public let displayClass: String?
    /// The App Store feature whose limit `maxCount` is, e.g. `APP_STORE_VERSIONS`.
    public let feature: String?
    /// Accepted pixel sizes, `"WxH"`.
    public let sizes: [String]
    public let maxCount: Int?

    public init(
        id: String,
        placementType: AssetPlacementType,
        platform: String?,
        displayClass: String?,
        feature: String?,
        sizes: [String],
        maxCount: Int?
    ) {
        self.id = id
        self.placementType = placementType
        self.platform = platform
        self.displayClass = displayClass
        self.feature = feature
        self.sizes = sizes
        self.maxCount = maxCount
    }
}

extension AssetPlacementGroup: Codable {
    enum CodingKeys: String, CodingKey {
        case id, placementType, platform, displayClass, feature, sizes, maxCount
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        placementType = try c.decode(AssetPlacementType.self, forKey: .placementType)
        platform = try c.decodeIfPresent(String.self, forKey: .platform)
        displayClass = try c.decodeIfPresent(String.self, forKey: .displayClass)
        feature = try c.decodeIfPresent(String.self, forKey: .feature)
        sizes = try c.decode([String].self, forKey: .sizes)
        maxCount = try c.decodeIfPresent(Int.self, forKey: .maxCount)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(placementType, forKey: .placementType)
        try c.encodeIfPresent(platform, forKey: .platform)
        try c.encodeIfPresent(displayClass, forKey: .displayClass)
        try c.encodeIfPresent(feature, forKey: .feature)
        try c.encode(sizes, forKey: .sizes)
        try c.encodeIfPresent(maxCount, forKey: .maxCount)
    }
}

extension AssetPlacementGroup: Presentable {
    public static var tableHeaders: [String] { ["Type", "Group", "Platform", "Display Class", "Feature", "Sizes", "Max"] }
    public var tableRow: [String] {
        [
            placementType.rawValue, id, platform ?? "-", displayClass ?? "-", feature ?? "-",
            sizes.joined(separator: ", "), maxCount.map(String.init) ?? "-",
        ]
    }
}

extension AssetPlacementGroup: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "place", command: "asset-placements", action: "create", params: [
                "image-id": "<image-id>",
                "localization-id": "<localization-id>",
                "placement-group": id,
                "placement-type": placementType.rawValue,
            ]),
        ]
    }
}

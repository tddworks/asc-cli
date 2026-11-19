/// What happened — or, on a dry run, what will happen — to one locale's screenshots in one placement group.
public enum ScreenshotImportStatus: String, Sendable, Equatable, Codable, CaseIterable {
    /// Dry run: the screenshots would be uploaded and placed.
    case planned
    case placed
    /// The localization already has screenshots in the group and `--existing` is `fail`.
    case conflict
    /// The size fits several placement groups — `--placement-group` picks one.
    case ambiguous
    case noMatchingGroup
    /// More screenshots than the group allows.
    case overLimit
    case failed

    public var isSuccess: Bool { self == .planned || self == .placed }
}

/// One screenshot of the group; ids and position are known once it's placed.
public struct ScreenshotImportPlacement: Sendable, Equatable, Codable {
    /// The file's path inside the export ZIP.
    public let file: String
    public let imageId: String?
    public let placementId: String?
    /// 1-based display order within the group.
    public let position: Int?

    public init(file: String, imageId: String? = nil, placementId: String? = nil, position: Int? = nil) {
        self.file = file
        self.imageId = imageId
        self.placementId = placementId
        self.position = position
    }

    enum CodingKeys: String, CodingKey { case file, imageId, placementId, position }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(file, forKey: .file)
        try c.encodeIfPresent(imageId, forKey: .imageId)
        try c.encodeIfPresent(placementId, forKey: .placementId)
        try c.encodeIfPresent(position, forKey: .position)
    }
}

/// The outcome of `asc screenshots import --to-library` for one locale and placement group.
public struct ScreenshotImportGroupResult: Sendable, Equatable {
    public let locale: String
    /// `nil` while the version has no localization for the locale (dry run).
    public let localizationId: String?
    /// The version the localization belongs to — offered back in the `replace` command, not shown.
    public let versionId: String?
    /// `nil` when no single group could be chosen.
    public let placementGroup: String?
    public let status: ScreenshotImportStatus
    public let placements: [ScreenshotImportPlacement]
    public let message: String?
    public let existingPlacementIds: [String]?
    public let candidates: [String]?

    public init(
        locale: String,
        localizationId: String?,
        versionId: String?,
        placementGroup: String?,
        status: ScreenshotImportStatus,
        placements: [ScreenshotImportPlacement],
        message: String? = nil,
        existingPlacementIds: [String]? = nil,
        candidates: [String]? = nil
    ) {
        self.locale = locale
        self.localizationId = localizationId
        self.versionId = versionId
        self.placementGroup = placementGroup
        self.status = status
        self.placements = placements
        self.message = message
        self.existingPlacementIds = existingPlacementIds
        self.candidates = candidates
    }
}

extension ScreenshotImportGroupResult: Codable {
    enum CodingKeys: String, CodingKey {
        case locale, localizationId, versionId, placementGroup, status, placements, message, existingPlacementIds, candidates
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            locale: try c.decode(String.self, forKey: .locale),
            localizationId: try c.decodeIfPresent(String.self, forKey: .localizationId),
            versionId: try c.decodeIfPresent(String.self, forKey: .versionId),
            placementGroup: try c.decodeIfPresent(String.self, forKey: .placementGroup),
            status: try c.decode(ScreenshotImportStatus.self, forKey: .status),
            placements: try c.decode([ScreenshotImportPlacement].self, forKey: .placements),
            message: try c.decodeIfPresent(String.self, forKey: .message),
            existingPlacementIds: try c.decodeIfPresent([String].self, forKey: .existingPlacementIds),
            candidates: try c.decodeIfPresent([String].self, forKey: .candidates)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(locale, forKey: .locale)
        try c.encodeIfPresent(localizationId, forKey: .localizationId)
        try c.encodeIfPresent(placementGroup, forKey: .placementGroup)
        try c.encode(status, forKey: .status)
        try c.encode(placements, forKey: .placements)
        try c.encodeIfPresent(message, forKey: .message)
        try c.encodeIfPresent(existingPlacementIds, forKey: .existingPlacementIds)
        try c.encodeIfPresent(candidates, forKey: .candidates)
    }
}

extension ScreenshotImportGroupResult: Presentable {
    public static var tableHeaders: [String] { ["Locale", "Group", "Status", "Screenshots", "Message"] }
    public var tableRow: [String] {
        [locale, placementGroup ?? "-", status.rawValue, String(placements.count), message ?? ""]
    }
}

extension ScreenshotImportGroupResult: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = []
        if let localizationId {
            items.append(Affordance(key: "listPlacements", command: "asset-placements", action: "list",
                                    params: ["localization-id": localizationId]))
        }
        if status == .noMatchingGroup {
            items.append(Affordance(key: "listPlacementGroups", command: "asset-placement-groups", action: "list",
                                    params: ["placement-type": AssetPlacementType.appScreenshot.rawValue]))
        }
        if status == .conflict, let versionId {
            items.append(Affordance(key: "replace", command: "screenshots", action: "import", params: [
                "existing": ExistingScreenshotsPolicy.replace.rawValue,
                "from": "<zip>",
                "version-id": versionId,
            ], flags: ["to-library"]))
        }
        return items
    }
}

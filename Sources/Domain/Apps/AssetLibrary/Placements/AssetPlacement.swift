/// The localization a placement sits on.
public enum PlacementSurface: String, Sendable, Equatable, Codable, CaseIterable {
    case appStoreVersionLocalization = "APP_STORE_VERSION_LOCALIZATION"
    case experimentTreatmentLocalization = "EXPERIMENT_TREATMENT_LOCALIZATION"
    case customProductPageLocalization = "CUSTOM_PRODUCT_PAGE_LOCALIZATION"
    case eventLocalization = "EVENT_LOCALIZATION"

    /// In-app event placements allow one asset per group, so App Store Connect has nothing to order.
    public var isOrderable: Bool { self != .eventLocalization }

    /// The `asset-placements` flag that names a localization of this surface, or `nil` when
    /// asc has no command for the surface.
    public var cliParam: String? {
        switch self {
        case .appStoreVersionLocalization: "localization-id"
        case .experimentTreatmentLocalization, .customProductPageLocalization, .eventLocalization: nil
        }
    }
}

/// A placement's state mirrors the review state of the surface it sits on.
public enum PlacementState: String, Sendable, Equatable, Codable, CaseIterable {
    case assetProcessing = "ASSET_PROCESSING"
    case failed = "FAILED"
    case parentPrepareForSubmission = "PARENT_PREPARE_FOR_SUBMISSION"
    case parentReadyForReview = "PARENT_READY_FOR_REVIEW"
    case parentWaitingForReview = "PARENT_WAITING_FOR_REVIEW"
    case parentInReview = "PARENT_IN_REVIEW"
    case parentApproved = "PARENT_APPROVED"

    /// The asset behind the placement is still being processed.
    public var isProcessing: Bool { self == .assetProcessing }

    /// The placement can still be deleted or reordered.
    public var isEditable: Bool { [.assetProcessing, .failed, .parentPrepareForSubmission].contains(self) }

    public var isInReview: Bool { [.parentReadyForReview, .parentWaitingForReview, .parentInReview].contains(self) }

    public var isLive: Bool { self == .parentApproved }
}

/// One library asset shown in one slot of one localization (ASC API: `appAssetLibraryPlacements`).
public struct AssetPlacement: Sendable, Equatable, Identifiable {
    public let id: String
    public let surface: PlacementSurface
    /// Parent localization identifier — injected by Infrastructure.
    public let localizationId: String
    public let mediaType: AssetMediaType
    public let assetId: String
    public let placementType: AssetPlacementType
    public let placementGroup: String
    /// 1-based display order within the placement group, when read from the localization.
    public let position: Int?
    public let state: PlacementState
    public let stateDetails: [AssetStateDetail]?

    public init(
        id: String,
        surface: PlacementSurface,
        localizationId: String,
        mediaType: AssetMediaType,
        assetId: String,
        placementType: AssetPlacementType,
        placementGroup: String,
        position: Int? = nil,
        state: PlacementState,
        stateDetails: [AssetStateDetail]? = nil
    ) {
        self.id = id
        self.surface = surface
        self.localizationId = localizationId
        self.mediaType = mediaType
        self.assetId = assetId
        self.placementType = placementType
        self.placementGroup = placementGroup
        self.position = position
        self.state = state
        self.stateDetails = stateDetails
    }
}

extension AssetPlacement: Codable {
    enum CodingKeys: String, CodingKey {
        case id, surface, localizationId, mediaType, assetId, placementType, placementGroup, position, state, stateDetails
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        surface = try c.decode(PlacementSurface.self, forKey: .surface)
        localizationId = try c.decode(String.self, forKey: .localizationId)
        mediaType = try c.decode(AssetMediaType.self, forKey: .mediaType)
        assetId = try c.decode(String.self, forKey: .assetId)
        placementType = try c.decode(AssetPlacementType.self, forKey: .placementType)
        placementGroup = try c.decode(String.self, forKey: .placementGroup)
        position = try c.decodeIfPresent(Int.self, forKey: .position)
        state = try c.decode(PlacementState.self, forKey: .state)
        stateDetails = try c.decodeIfPresent([AssetStateDetail].self, forKey: .stateDetails)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(surface, forKey: .surface)
        try c.encode(localizationId, forKey: .localizationId)
        try c.encode(mediaType, forKey: .mediaType)
        try c.encode(assetId, forKey: .assetId)
        try c.encode(placementType, forKey: .placementType)
        try c.encode(placementGroup, forKey: .placementGroup)
        try c.encodeIfPresent(position, forKey: .position)
        try c.encode(state, forKey: .state)
        try c.encodeIfPresent(stateDetails, forKey: .stateDetails)
    }
}

extension AssetPlacement: Presentable {
    public static var tableHeaders: [String] { ["ID", "Asset ID", "Type", "Group", "Position", "State"] }
    public var tableRow: [String] {
        [id, assetId, placementType.rawValue, placementGroup, position.map(String.init) ?? "-", state.rawValue]
    }
}

extension AssetPlacement: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "listAssetPlacements", command: "asset-placements", action: "list",
                       params: [mediaType.assetParam: assetId]),
        ]
        let surfaceParam = surface.cliParam
        if let surfaceParam {
            items.append(Affordance(key: "listPlacements", command: "asset-placements", action: "list",
                                    params: [surfaceParam: localizationId]))
        }
        if state.isEditable {
            items.append(Affordance(key: "delete", command: "asset-placements", action: "delete", params: ["placement-id": id]))
            if surface.isOrderable, let surfaceParam {
                items.append(Affordance(key: "reorderGroup", command: "asset-placements", action: "reorder", params: [
                    surfaceParam: localizationId,
                    "placement-group": placementGroup,
                    "placement-ids": "<placement-ids>",
                ]))
            }
        }
        return items
    }
}

extension AssetMediaType {
    /// The `asset-placements` flag naming an asset of this media type.
    var assetParam: String {
        switch self {
        case .image: "image-id"
        case .video: "video-id"
        }
    }
}

/// An image uploaded once into the app's asset library (ASC API: `appAssetLibraryImages`).
public struct LibraryImage: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent library identifier — injected by Infrastructure.
    public let libraryId: String
    public let fileName: String
    public let fileSize: Int
    public let category: AssetCategory
    public let state: LibraryAssetState
    public let referenceName: String?
    /// The specification App Store Connect matched the file to during processing.
    public let specId: String?
    public let width: Int?
    public let height: Int?
    public let templateUrl: String?
    public let stateDetails: [AssetStateDetail]?
    public let createdDate: String?

    public init(
        id: String,
        libraryId: String,
        fileName: String,
        fileSize: Int,
        category: AssetCategory,
        state: LibraryAssetState,
        referenceName: String? = nil,
        specId: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        templateUrl: String? = nil,
        stateDetails: [AssetStateDetail]? = nil,
        createdDate: String? = nil
    ) {
        self.id = id
        self.libraryId = libraryId
        self.fileName = fileName
        self.fileSize = fileSize
        self.category = category
        self.state = state
        self.referenceName = referenceName
        self.specId = specId
        self.width = width
        self.height = height
        self.templateUrl = templateUrl
        self.stateDetails = stateDetails
        self.createdDate = createdDate
    }
}

extension LibraryImage: Codable {
    enum CodingKeys: String, CodingKey {
        case id, libraryId, fileName, fileSize, category, state
        case referenceName, specId, width, height, templateUrl, stateDetails, createdDate
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        libraryId = try c.decode(String.self, forKey: .libraryId)
        fileName = try c.decode(String.self, forKey: .fileName)
        fileSize = try c.decode(Int.self, forKey: .fileSize)
        category = try c.decode(AssetCategory.self, forKey: .category)
        state = try c.decode(LibraryAssetState.self, forKey: .state)
        referenceName = try c.decodeIfPresent(String.self, forKey: .referenceName)
        specId = try c.decodeIfPresent(String.self, forKey: .specId)
        width = try c.decodeIfPresent(Int.self, forKey: .width)
        height = try c.decodeIfPresent(Int.self, forKey: .height)
        templateUrl = try c.decodeIfPresent(String.self, forKey: .templateUrl)
        stateDetails = try c.decodeIfPresent([AssetStateDetail].self, forKey: .stateDetails)
        createdDate = try c.decodeIfPresent(String.self, forKey: .createdDate)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(libraryId, forKey: .libraryId)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(fileSize, forKey: .fileSize)
        try c.encode(category, forKey: .category)
        try c.encode(state, forKey: .state)
        try c.encodeIfPresent(referenceName, forKey: .referenceName)
        try c.encodeIfPresent(specId, forKey: .specId)
        try c.encodeIfPresent(width, forKey: .width)
        try c.encodeIfPresent(height, forKey: .height)
        try c.encodeIfPresent(templateUrl, forKey: .templateUrl)
        try c.encodeIfPresent(stateDetails, forKey: .stateDetails)
        try c.encodeIfPresent(createdDate, forKey: .createdDate)
    }
}

extension LibraryImage: Presentable {
    public static var tableHeaders: [String] { ["ID", "File Name", "Category", "State", "Reference Name"] }
    public var tableRow: [String] { [id, fileName, category.rawValue, state.rawValue, referenceName ?? ""] }
}

extension LibraryImage: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        LibraryAssetAffordances(
            command: "asset-images", idParam: "image-id", id: id, libraryId: libraryId,
            state: state, placementType: category.suggestedPlacementType(for: .image)
        ).affordances(listKey: "listImages")
    }
}

/// Affordances shared by library images and videos: navigation, delete unless in review,
/// place once processed (refresh while processing), archive once approved.
struct LibraryAssetAffordances {
    let command: String
    let idParam: String
    let id: String
    let libraryId: String
    let state: LibraryAssetState
    let placementType: String

    func affordances(listKey: String) -> [Affordance] {
        var items: [Affordance] = [
            Affordance(key: listKey, command: command, action: "list", params: ["library-id": libraryId]),
            Affordance(key: "listPlacements", command: "asset-placements", action: "list", params: [idParam: id]),
        ]
        if !state.isInReview {
            items.append(Affordance(key: "delete", command: command, action: "delete", params: [idParam: id]))
        }
        if state.isPlaceable {
            items.append(Affordance(key: "place", command: "asset-placements", action: "create", params: [
                idParam: id,
                "localization-id": "<localization-id>",
                "placement-group": "<placement-group>",
                "placement-type": placementType,
            ]))
        } else if state.isAwaitingUpload || state.isProcessing {
            items.append(Affordance(key: "refresh", command: command, action: "list", params: [idParam: id, "library-id": libraryId]))
        }
        if state.isArchivable {
            items.append(Affordance(key: "archive", command: command, action: "update", params: [idParam: id, "library-id": libraryId, "archived": "true"]))
        }
        return items
    }
}

extension AssetCategory {
    /// Screenshots-and-previews assets go into the screenshot (image) or preview (video)
    /// slot; creative assets fit several slots, so the user picks one.
    func suggestedPlacementType(for mediaType: AssetMediaType) -> String {
        switch (self, mediaType) {
        case (.appScreenshotsAndPreviews, .image): AssetPlacementType.appScreenshot.rawValue
        case (.appScreenshotsAndPreviews, .video): AssetPlacementType.appPreview.rawValue
        case (.creativeAssets, _): "<placement-type>"
        }
    }
}

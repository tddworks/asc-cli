/// A video (e.g. an app preview) uploaded once into the app's asset library
/// (ASC API: `appAssetLibraryVideos`).
public struct LibraryVideo: Sendable, Equatable, Identifiable {
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
    /// Preview frame size.
    public let width: Int?
    public let height: Int?
    public let stateDetails: [AssetStateDetail]?
    public let createdDate: String?
    /// The frame that represents the video, `HH:MM:SS:FF`.
    public let previewFrameTimeCode: String?
    /// `PROCESSING`, `COMPLETE` or `FAILED` while App Store Connect renders the frame.
    public let previewFrameState: String?
    public let previewFrameUrl: String?
    public let videoUrl: String?

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
        stateDetails: [AssetStateDetail]? = nil,
        createdDate: String? = nil,
        previewFrameTimeCode: String? = nil,
        previewFrameState: String? = nil,
        previewFrameUrl: String? = nil,
        videoUrl: String? = nil
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
        self.stateDetails = stateDetails
        self.createdDate = createdDate
        self.previewFrameTimeCode = previewFrameTimeCode
        self.previewFrameState = previewFrameState
        self.previewFrameUrl = previewFrameUrl
        self.videoUrl = videoUrl
    }
}

extension LibraryVideo: Codable {
    enum CodingKeys: String, CodingKey {
        case id, libraryId, fileName, fileSize, category, state
        case referenceName, specId, width, height, stateDetails, createdDate
        case previewFrameTimeCode, previewFrameState, previewFrameUrl, videoUrl
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
        stateDetails = try c.decodeIfPresent([AssetStateDetail].self, forKey: .stateDetails)
        createdDate = try c.decodeIfPresent(String.self, forKey: .createdDate)
        previewFrameTimeCode = try c.decodeIfPresent(String.self, forKey: .previewFrameTimeCode)
        previewFrameState = try c.decodeIfPresent(String.self, forKey: .previewFrameState)
        previewFrameUrl = try c.decodeIfPresent(String.self, forKey: .previewFrameUrl)
        videoUrl = try c.decodeIfPresent(String.self, forKey: .videoUrl)
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
        try c.encodeIfPresent(stateDetails, forKey: .stateDetails)
        try c.encodeIfPresent(createdDate, forKey: .createdDate)
        try c.encodeIfPresent(previewFrameTimeCode, forKey: .previewFrameTimeCode)
        try c.encodeIfPresent(previewFrameState, forKey: .previewFrameState)
        try c.encodeIfPresent(previewFrameUrl, forKey: .previewFrameUrl)
        try c.encodeIfPresent(videoUrl, forKey: .videoUrl)
    }
}

extension LibraryVideo: Presentable {
    public static var tableHeaders: [String] { ["ID", "File Name", "Category", "State", "Reference Name"] }
    public var tableRow: [String] { [id, fileName, category.rawValue, state.rawValue, referenceName ?? ""] }
}

extension LibraryVideo: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        LibraryAssetAffordances(
            command: "asset-videos", idParam: "video-id", id: id, libraryId: libraryId,
            state: state, placementType: category.suggestedPlacementType(for: .video)
        ).affordances(listKey: "listVideos")
    }
}

public struct AppPreview: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent preview set identifier — always present so agents can correlate responses.
    public let setId: String
    public let fileName: String
    public let fileSize: Int
    public let mimeType: String?
    public let assetDeliveryState: AssetDeliveryState?
    public let videoDeliveryState: VideoDeliveryState?
    public let videoURL: String?
    public let previewFrameTimeCode: String?

    public init(
        id: String,
        setId: String,
        fileName: String,
        fileSize: Int,
        mimeType: String? = nil,
        assetDeliveryState: AssetDeliveryState? = nil,
        videoDeliveryState: VideoDeliveryState? = nil,
        videoURL: String? = nil,
        previewFrameTimeCode: String? = nil
    ) {
        self.id = id
        self.setId = setId
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.assetDeliveryState = assetDeliveryState
        self.videoDeliveryState = videoDeliveryState
        self.videoURL = videoURL
        self.previewFrameTimeCode = previewFrameTimeCode
    }

    /// True when the video has been fully encoded and is ready for display.
    public var isComplete: Bool { videoDeliveryState == .complete }

    /// True when upload or video processing has failed.
    public var hasFailed: Bool {
        assetDeliveryState == .failed || videoDeliveryState == .failed
    }

    public var fileSizeDescription: String {
        let bytes = Double(fileSize)
        if bytes < 1024 { return "\(fileSize) B" }
        if bytes < 1_048_576 { return String(format: "%.1f KB", bytes / 1024) }
        return String(format: "%.1f MB", bytes / 1_048_576)
    }

    // MARK: - Asset Delivery State (upload progress — same 4 states as screenshots)

    public enum AssetDeliveryState: String, Sendable, Equatable, Codable {
        case awaitingUpload = "AWAITING_UPLOAD"
        case uploadComplete = "UPLOAD_COMPLETE"
        case complete = "COMPLETE"
        case failed = "FAILED"

        public var displayName: String {
            switch self {
            case .awaitingUpload: return "Awaiting Upload"
            case .uploadComplete: return "Upload Complete"
            case .complete: return "Complete"
            case .failed: return "Failed"
            }
        }
    }

    // MARK: - Video Delivery State (video encoding after upload — 5 states, unique to previews)

    public enum VideoDeliveryState: String, Sendable, Equatable, Codable {
        case awaitingUpload = "AWAITING_UPLOAD"
        case uploadComplete = "UPLOAD_COMPLETE"
        case processing = "PROCESSING"
        case complete = "COMPLETE"
        case failed = "FAILED"

        public var isProcessing: Bool { self == .processing }
        public var isComplete: Bool { self == .complete }
        public var hasFailed: Bool { self == .failed }

        public var displayName: String {
            switch self {
            case .awaitingUpload: return "Awaiting Upload"
            case .uploadComplete: return "Upload Complete"
            case .processing: return "Processing"
            case .complete: return "Complete"
            case .failed: return "Failed"
            }
        }
    }
}

// MARK: - Codable (nil fields omitted from JSON output)

extension AppPreview: Codable {
    enum CodingKeys: String, CodingKey {
        case id, setId, fileName, fileSize, mimeType
        case assetDeliveryState, videoDeliveryState, videoURL, previewFrameTimeCode
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        setId = try c.decode(String.self, forKey: .setId)
        fileName = try c.decode(String.self, forKey: .fileName)
        fileSize = try c.decode(Int.self, forKey: .fileSize)
        mimeType = try c.decodeIfPresent(String.self, forKey: .mimeType)
        assetDeliveryState = try c.decodeIfPresent(AssetDeliveryState.self, forKey: .assetDeliveryState)
        videoDeliveryState = try c.decodeIfPresent(VideoDeliveryState.self, forKey: .videoDeliveryState)
        videoURL = try c.decodeIfPresent(String.self, forKey: .videoURL)
        previewFrameTimeCode = try c.decodeIfPresent(String.self, forKey: .previewFrameTimeCode)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(setId, forKey: .setId)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(fileSize, forKey: .fileSize)
        try c.encodeIfPresent(mimeType, forKey: .mimeType)
        try c.encodeIfPresent(assetDeliveryState, forKey: .assetDeliveryState)
        try c.encodeIfPresent(videoDeliveryState, forKey: .videoDeliveryState)
        try c.encodeIfPresent(videoURL, forKey: .videoURL)
        try c.encodeIfPresent(previewFrameTimeCode, forKey: .previewFrameTimeCode)
    }
}

// MARK: - AffordanceProviding

extension AppPreview: AffordanceProviding {
    public var affordances: [String: String] {
        ["listPreviews": "asc app-previews list --set-id \(setId)"]
    }
}

public struct AppScreenshot: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    /// Parent screenshot set identifier — always present so agents can correlate responses.
    public let setId: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetDeliveryState?
    public let imageWidth: Int?
    public let imageHeight: Int?

    public init(
        id: String,
        setId: String,
        fileName: String,
        fileSize: Int,
        assetState: AssetDeliveryState? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil
    ) {
        self.id = id
        self.setId = setId
        self.fileName = fileName
        self.fileSize = fileSize
        self.assetState = assetState
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }

    public var isComplete: Bool { assetState == .complete }

    public var fileSizeDescription: String {
        let bytes = Double(fileSize)
        if bytes < 1024 { return "\(fileSize) B" }
        if bytes < 1_048_576 { return String(format: "%.1f KB", bytes / 1024) }
        return String(format: "%.1f MB", bytes / 1_048_576)
    }

    public var dimensionsDescription: String? {
        guard let w = imageWidth, let h = imageHeight else { return nil }
        return "\(w) × \(h)"
    }

    public enum AssetDeliveryState: String, Sendable, Equatable, Codable {
        case awaitingUpload = "AWAITING_UPLOAD"
        case uploadComplete = "UPLOAD_COMPLETE"
        case complete = "COMPLETE"
        case failed = "FAILED"

        public var isComplete: Bool { self == .complete }
        public var hasFailed: Bool { self == .failed }

        public var displayName: String {
            switch self {
            case .awaitingUpload: return "Awaiting Upload"
            case .uploadComplete: return "Upload Complete"
            case .complete: return "Complete"
            case .failed: return "Failed"
            }
        }
    }
}

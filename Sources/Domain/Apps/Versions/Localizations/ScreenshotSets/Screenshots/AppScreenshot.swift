public struct AppScreenshot: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    /// Parent screenshot set identifier — always present so agents can correlate responses.
    public let setId: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetDeliveryState?
    public let imageWidth: Int?
    public let imageHeight: Int?
    /// Template URL from the API with `{w}`, `{h}`, `{f}` placeholders.
    public let sourceUrl: String?

    public init(
        id: String,
        setId: String,
        fileName: String,
        fileSize: Int,
        assetState: AssetDeliveryState? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        sourceUrl: String? = nil
    ) {
        self.id = id
        self.setId = setId
        self.fileName = fileName
        self.fileSize = fileSize
        self.assetState = assetState
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.sourceUrl = sourceUrl
    }

    public var isComplete: Bool { assetState == .complete }

    /// Resolved image URL with actual dimensions and png format, or nil if template or dimensions are unavailable.
    public var imageUrl: String? {
        guard let sourceUrl, let w = imageWidth, let h = imageHeight else { return nil }
        return sourceUrl
            .replacingOccurrences(of: "{w}", with: "\(w)")
            .replacingOccurrences(of: "{h}", with: "\(h)")
            .replacingOccurrences(of: "{f}", with: "png")
    }

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

extension AppScreenshot: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "File Name", "State", "Dimensions"]
    }
    public var tableRow: [String] {
        [id, fileName, assetState?.displayName ?? "-", dimensionsDescription ?? "-"]
    }
}

extension AppScreenshot: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listScreenshots", command: "screenshots", action: "list", params: ["set-id": setId]),
        ]
    }
}

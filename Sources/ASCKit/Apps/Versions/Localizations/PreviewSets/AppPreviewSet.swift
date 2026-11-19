import Foundation

public struct AppPreviewSet: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent localization identifier — always present so agents can correlate responses.
    public let localizationId: String
    public let previewType: PreviewType
    public let previewsCount: Int

    public init(
        id: String,
        localizationId: String,
        previewType: PreviewType,
        previewsCount: Int = 0
    ) {
        self.id = id
        self.localizationId = localizationId
        self.previewType = previewType
        self.previewsCount = previewsCount
    }

    public var isEmpty: Bool { previewsCount == 0 }
    public var deviceCategory: PreviewType.DeviceCategory { previewType.deviceCategory }
    public var displayTypeName: String { previewType.displayName }
}

// MARK: - AffordanceProviding

extension AppPreviewSet: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listPreviews": "asc app-previews list --set-id \(id)",
            "listPreviewSets": "asc app-preview-sets list --localization-id \(localizationId)",
        ]
    }
}

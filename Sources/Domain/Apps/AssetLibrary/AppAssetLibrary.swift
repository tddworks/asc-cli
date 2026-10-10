/// The per-app container of reusable marketing media (ASC API: `appAssetLibraries`).
/// Each app has exactly one; images and videos are uploaded into it once and then placed
/// on App Store surfaces.
public struct AppAssetLibrary: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure.
    public let appId: String

    public init(id: String, appId: String) {
        self.id = id
        self.appId = appId
    }
}

extension AppAssetLibrary: Presentable {
    public static var tableHeaders: [String] { ["ID", "App ID"] }
    public var tableRow: [String] { [id, appId] }
}

extension AppAssetLibrary: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listImages", command: "asset-images", action: "list", params: ["library-id": id]),
            Affordance(key: "listVideos", command: "asset-videos", action: "list", params: ["library-id": id]),
            Affordance(key: "listPlacementGroups", command: "asset-placement-groups", action: "list",
                       params: ["placement-type": AssetPlacementType.appScreenshot.rawValue]),
            Affordance(key: "uploadImage", command: "asset-images", action: "upload",
                       params: ["library-id": id, "file": "<file>"]),
        ]
    }
}

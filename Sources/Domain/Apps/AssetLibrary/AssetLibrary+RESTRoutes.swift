/// REST route registrations for the App Asset Library: the library under an app, its
/// images, and placements — which hang off either the localization they sit on or the
/// asset they show. Localization parents are registered first so `create` (which names
/// both the localization and the asset) posts to the localization's collection.
extension RESTPathResolver {
    static let _assetLibraryRoutes: Void = {
        registerRoute(command: "asset-library", parentParam: "app-id", parentSegment: "apps", segment: "asset-library")
        registerRoute(command: "asset-images", parentParam: "library-id", parentSegment: "asset-library", segment: "images", resourceParam: "image-id")
        registerRoute(command: "asset-videos", parentParam: "library-id", parentSegment: "asset-library", segment: "videos", resourceParam: "video-id")
        registerRoute(command: "asset-placements", parentParam: "localization-id", parentSegment: "version-localizations", segment: "placements")
        registerRoute(command: "asset-placements", parentParam: "treatment-localization-id", parentSegment: "experiment-treatment-localizations", segment: "placements")
        registerRoute(command: "asset-placements", parentParam: "image-id", parentSegment: "asset-images", segment: "placements")
        registerRoute(command: "asset-placements", parentParam: "video-id", parentSegment: "asset-videos", segment: "placements")
    }()
}

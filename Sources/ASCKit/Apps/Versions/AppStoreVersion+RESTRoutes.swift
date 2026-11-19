/// REST route registrations for Version and its children (localizations, screenshots, previews).
extension RESTPathResolver {
    static let _versionRoutes: Void = {
        registerRoute(command: "version-localizations", parentParam: "version-id", parentSegment: "versions", segment: "localizations")
        registerRoute(command: "version-review-detail", parentParam: "version-id", parentSegment: "versions", segment: "review-detail")
        registerRoute(command: "screenshot-sets", parentParam: "localization-id", parentSegment: "version-localizations", segment: "screenshot-sets")
        registerRoute(command: "screenshots", parentParam: "set-id", parentSegment: "screenshot-sets", segment: "screenshots")
        registerRoute(command: "app-preview-sets", parentParam: "localization-id", parentSegment: "version-localizations", segment: "preview-sets")
        registerRoute(command: "app-previews", parentParam: "set-id", parentSegment: "app-preview-sets", segment: "previews")
    }()
}

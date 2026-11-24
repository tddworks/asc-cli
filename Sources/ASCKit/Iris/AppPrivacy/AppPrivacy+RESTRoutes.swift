/// REST routes for App Privacy.
extension RESTPathResolver {
    static let _appPrivacyRoutes: Void = {
        // One label per app:
        // `asc iris app-privacy get --app-id A`     → GET  /api/v1/iris/apps/A/app-privacy
        // `… declare --app-id A` / `… publish …`    → POST /api/v1/iris/apps/A/app-privacy/{declare|publish}
        registerRoute(command: "iris app-privacy", parentParam: "app-id", parentSegment: "iris/apps", segment: "app-privacy")
    }()
}

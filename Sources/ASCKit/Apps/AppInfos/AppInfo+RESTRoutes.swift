/// REST route registrations for AppInfo children.
extension RESTPathResolver {
    static let _appInfoRoutes: Void = {
        registerRoute(command: "app-info-localizations", parentParam: "app-info-id", parentSegment: "app-infos", segment: "localizations")
        registerRoute(command: "age-rating", parentParam: "app-info-id", parentSegment: "app-infos", segment: "age-rating")
    }()
}

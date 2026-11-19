/// REST route registrations for app-shots (screenshot generation).
extension RESTPathResolver {
    static let _appShotsRoutes: Void = {
        registerRoute(command: "app-shots-templates", parentParam: "", parentSegment: "", segment: "app-shots/templates")
        registerRoute(command: "app-shots-themes", parentParam: "", parentSegment: "", segment: "app-shots/themes")
    }()
}

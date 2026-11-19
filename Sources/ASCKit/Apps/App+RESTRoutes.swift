/// REST route registrations for App and its direct children.
extension RESTPathResolver {
    static let _appRoutes: Void = {
        registerRoute(command: "versions", parentParam: "app-id", parentSegment: "apps", segment: "versions")
        registerRoute(command: "builds", parentParam: "app-id", parentSegment: "apps", segment: "builds")
        registerRoute(command: "reviews", parentParam: "app-id", parentSegment: "apps", segment: "reviews")
        registerRoute(command: "app-infos", parentParam: "app-id", parentSegment: "apps", segment: "app-infos")
        registerRoute(command: "testflight", parentParam: "app-id", parentSegment: "apps", segment: "testflight")
        registerRoute(command: "iap", parentParam: "app-id", parentSegment: "apps", segment: "iap")
        registerRoute(command: "subscription-groups", parentParam: "app-id", parentSegment: "apps", segment: "subscription-groups")
        registerRoute(command: "xcode-cloud", parentParam: "app-id", parentSegment: "apps", segment: "xcode-cloud")
        registerRoute(command: "perf-metrics", parentParam: "app-id", parentSegment: "apps", segment: "perf-metrics")
        registerRoute(command: "diagnostics", parentParam: "app-id", parentSegment: "apps", segment: "diagnostics")
        registerRoute(command: "app-clips", parentParam: "app-id", parentSegment: "apps", segment: "app-clips")
    }()
}

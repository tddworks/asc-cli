/// REST route registrations for TestFlight / beta review.
extension RESTPathResolver {
    static let _testFlightRoutes: Void = {
        registerRoute(command: "beta-review", parentParam: "build-id", parentSegment: "builds", segment: "beta-review")
        registerRoute(command: "beta-build-localizations", parentParam: "build-id", parentSegment: "builds", segment: "beta-localizations")
        registerRoute(command: "beta-app-localizations", parentParam: "app-id", parentSegment: "apps", segment: "beta-app-localizations")
    }()
}

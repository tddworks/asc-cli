/// REST route registrations for Product Page Optimization tests and their children.
extension RESTPathResolver {
    static let _experimentRoutes: Void = {
        registerRoute(command: "experiments", parentParam: "app-id", parentSegment: "apps", segment: "experiments")
        registerRoute(command: "experiment-treatments", parentParam: "experiment-id", parentSegment: "experiments", segment: "experiment-treatments")
        registerRoute(command: "experiment-treatment-localizations", parentParam: "treatment-id", parentSegment: "experiment-treatments", segment: "experiment-treatment-localizations")
    }()
}

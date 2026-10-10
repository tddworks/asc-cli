/// REST route registrations for build performance metrics and diagnostics.
/// (`perf-metrics` under an app is registered with the other app children.)
extension RESTPathResolver {
    static let _performanceRoutes: Void = {
        registerRoute(command: "perf-metrics", parentParam: "build-id", parentSegment: "builds", segment: "perf-metrics")
        registerRoute(command: "diagnostics", parentParam: "build-id", parentSegment: "builds", segment: "diagnostics")
        registerRoute(command: "diagnostic-logs", parentParam: "signature-id", parentSegment: "diagnostics", segment: "logs")
    }()
}

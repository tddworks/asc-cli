/// REST route registrations for Xcode Cloud hierarchy.
extension RESTPathResolver {
    static let _xcodeCloudRoutes: Void = {
        registerRoute(command: "xcode-cloud-workflows", parentParam: "product-id", parentSegment: "xcode-cloud", segment: "workflows")
        registerRoute(command: "xcode-cloud-build-runs", parentParam: "workflow-id", parentSegment: "xcode-cloud-workflows", segment: "build-runs")
    }()
}

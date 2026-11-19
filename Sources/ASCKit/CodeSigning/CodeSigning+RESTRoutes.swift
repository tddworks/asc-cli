/// REST route registrations for code signing resources.
extension RESTPathResolver {
    static let _codeSigningRoutes: Void = {
        registerRoute(command: "bundle-id-profiles", parentParam: "bundle-id-id", parentSegment: "bundle-ids", segment: "profiles")
    }()
}

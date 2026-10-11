/// `asc screenshots import --version-id V` posts the export ZIP to the version's screenshots.
extension RESTPathResolver {
    static let _screenshotImportRoutes: Void = {
        registerRoute(command: "screenshots", parentParam: "version-id", parentSegment: "versions", segment: "screenshots")
    }()
}

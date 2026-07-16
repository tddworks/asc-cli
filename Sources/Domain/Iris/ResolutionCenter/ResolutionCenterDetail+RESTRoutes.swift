/// REST route registration for the Resolution Center read.
extension RESTPathResolver {
    static let _resolutionCenterRoutes: Void = {
        // `asc iris resolution-center get --submission-id <id>` →
        // GET /api/v1/iris/review-submissions/<id>/resolution-center
        registerRoute(
            command: "iris resolution-center",
            parentParam: "submission-id",
            parentSegment: "iris/review-submissions",
            segment: "resolution-center"
        )
    }()
}

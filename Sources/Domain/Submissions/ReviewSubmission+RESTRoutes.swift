/// REST route registrations for ReviewSubmission and its children (items).
extension RESTPathResolver {
    static let _submissionRoutes: Void = {
        // `asc review-submissions items list --submission-id <id>` →
        // GET /api/v1/review-submissions/<id>/items
        registerRoute(
            command: "review-submissions items",
            parentParam: "submission-id",
            parentSegment: "review-submissions",
            segment: "items"
        )
    }()
}

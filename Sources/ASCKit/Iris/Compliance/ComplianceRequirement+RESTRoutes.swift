/// REST routes for App Compliance.
extension RESTPathResolver {
    static let _complianceRoutes: Void = {
        // `asc iris app-compliance list --app-id A` → GET /api/v1/iris/apps/A/compliance-requirements
        // `… declare --app-id A --requirement-id R` → POST /api/v1/iris/apps/A/compliance-requirements/R/declare
        // (a requirement id names the compliance on every app, so the row needs both ids)
        registerRoute(
            command: "iris app-compliance",
            parentParam: "app-id",
            parentSegment: "iris/apps",
            segment: "compliance-requirements",
            nestedResourceParam: "requirement-id"
        )
    }()
}

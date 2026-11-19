import ASCKit
import Hummingbird
import HummingbirdWebSocket

/// `POST /api/v1/versions/:versionId/submit` — submits an app version for review.
/// `?with-products=true` also sends every ready in-app purchase and subscription
/// version in the same review submission; `?dry-run=true` lists those items and
/// submits nothing. Query names match the CLI's `--with-products` / `--dry-run`.
struct VersionSubmissionController: Sendable {
    let submissionRepo: any SubmissionRepository
    let versionRepo: any VersionRepository
    let planner: SubmissionPlanner

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.post("/versions/:versionId/submit") { request, context -> Response in
            guard let versionId = context.parameters.get("versionId") else { return jsonError("Missing versionId") }
            let query = request.uri.queryParameters
            let withProducts = query["with-products"].map { $0 == "true" } ?? false
            let dryRun = query["dry-run"].map { $0 == "true" } ?? false

            guard withProducts || dryRun else {
                return try restFormat(try await self.submissionRepo.submitVersion(versionId: versionId))
            }
            let version = try await self.versionRepo.getVersion(id: versionId)
            let plan = try await self.planner.plan(for: version)
            if dryRun { return try restFormat(plan.items) }
            return try restFormat(try await plan.submit(repo: self.submissionRepo))
        }
    }
}

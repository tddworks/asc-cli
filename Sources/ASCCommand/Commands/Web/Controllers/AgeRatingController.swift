import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `AgeRatingDeclaration` resources.
struct AgeRatingController: Sendable {
    let repo: any AgeRatingDeclarationRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/age-rating/:appInfoId") { _, context -> Response in
            guard let appInfoId = context.parameters.get("appInfoId") else { return jsonError("Missing appInfoId") }
            let declaration = try await self.repo.getDeclaration(appInfoId: appInfoId)
            return try restFormat(declaration)
        }
    }
}

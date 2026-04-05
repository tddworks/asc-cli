import Domain
import Hummingbird
import ASCPlugin
import Infrastructure

/// GET /api/v1 — HATEOAS entry point listing all available resources.
struct RootController: Sendable {
    func addRoutes(to router: ASCRouter) {
        router.get("/api/v1") { _, _ -> Response in
            let formatter = OutputFormatter(format: .json, pretty: true)
            let json = try formatter.formatAgentItems([APIRoot()], headers: [], rowMapper: { _ in [] }, affordanceMode: .rest)
            return restResponse(json)
        }
    }
}

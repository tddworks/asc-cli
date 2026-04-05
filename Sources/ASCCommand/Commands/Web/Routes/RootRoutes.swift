import Domain
import Hummingbird
import ASCPlugin
import Infrastructure

/// GET /api/v1 — HATEOAS entry point listing all available resources.
enum RootRoutes {
    static func register(on router: ASCRouter) {
        router.get("/api/v1") { _, _ -> Response in
            try await restExec {
                let formatter = OutputFormatter(format: .json, pretty: true)
                return try formatter.formatAgentItems([APIRoot()], headers: [], rowMapper: { _ in [] }, affordanceMode: .rest)
            }
        }
    }
}

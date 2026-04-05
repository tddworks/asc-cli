import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Domain

/// /api/v1/simulators — Simulator routes.
struct SimulatorsController: Sendable {
    let repo: any SimulatorRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/simulators") { _, _ -> Response in
            let sims = try await self.repo.listSimulators(filter: .booted)
            return try restFormat(sims)
        }
    }
}

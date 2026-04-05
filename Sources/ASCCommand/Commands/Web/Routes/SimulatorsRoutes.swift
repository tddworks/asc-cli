import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Domain

/// /api/v1/simulators — Simulator routes.
enum SimulatorsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/simulators") { _, _ -> Response in
            let sims = try await ClientProvider.makeSimulatorRepository().listSimulators(filter: .booted)
            return try restFormat(sims)
        }
    }
}

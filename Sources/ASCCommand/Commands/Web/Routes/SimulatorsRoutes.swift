import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Domain

/// /api/v1/simulators — Simulator routes.
enum SimulatorsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/simulators") { _, _ -> Response in
            try await restExec { try await SimulatorsList.parse(["--pretty"]).execute(repo: ClientProvider.makeSimulatorRepository(), affordanceMode: .rest) }
        }
    }
}

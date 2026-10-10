import Foundation
import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// `GET /builds/:buildId/diagnostics?diagnostic-type=…` — a build's diagnostic signatures;
/// `GET /diagnostics/:signatureId/logs` — the logs behind one signature.
/// The query param matches the CLI flag `--diagnostic-type`.
struct DiagnosticsController: Sendable {
    let repo: any DiagnosticsRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/builds/:buildId/diagnostics") { request, context -> Response in
            guard let buildId = context.parameters.get("buildId") else { return jsonError("Missing buildId") }
            let diagnosticType = request.uri.queryParameters.get("diagnostic-type")
                .flatMap { DiagnosticType(rawValue: String($0)) }
            let signatures = try await self.repo.listSignatures(buildId: buildId, diagnosticType: diagnosticType)
            return try restFormat(signatures)
        }

        group.get("/diagnostics/:signatureId/logs") { _, context -> Response in
            guard let signatureId = context.parameters.get("signatureId") else { return jsonError("Missing signatureId") }
            let logs = try await self.repo.listLogs(signatureId: signatureId)
            return try restFormat(logs)
        }
    }
}

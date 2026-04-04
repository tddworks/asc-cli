import Foundation
import Hummingbird
import ASCPlugin
import Domain

/// Serves screenshot templates from the platform's `AggregateTemplateRepository`.
///
/// Templates are registered by plugins via `TemplateProvider`.
/// The web UI fetches from this endpoint to display the template grid.
enum TemplatesRoute {
    static func register(on router: ASCRouter) {
        // GET /api/templates — list all templates
        router.get("/api/templates") { _, _ in
            let templates = try await AggregateTemplateRepository.shared.listTemplates(size: nil)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(DataResponse(data: templates))
            return Response(status: .ok, headers: [.contentType: "application/json"],
                            body: .init(byteBuffer: .init(data: data)))
        }

        // GET /api/templates/{id} — get a specific template
        router.get("/api/templates/{id}") { _, context in
            guard let id = context.parameters.get("id") else {
                return errorResponse("Missing template id")
            }
            guard let template = try await AggregateTemplateRepository.shared.getTemplate(id: id) else {
                return errorResponse("Template '\(id)' not found", status: .notFound)
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(DataResponse(data: [template]))
            return Response(status: .ok, headers: [.contentType: "application/json"],
                            body: .init(byteBuffer: .init(data: data)))
        }
    }

    private static func errorResponse(_ message: String, status: HTTPResponse.Status = .badRequest) -> Response {
        let data = (try? JSONSerialization.data(withJSONObject: ["error": message])) ?? Data()
        return Response(status: status, headers: [.contentType: "application/json"],
                        body: .init(byteBuffer: .init(data: data)))
    }
}

/// Simple wrapper for JSON responses.
private struct DataResponse<T: Encodable>: Encodable {
    let data: T
}

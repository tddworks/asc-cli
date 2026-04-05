import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure

/// /api/v1/app-shots — Screenshot template and theme routes.
enum AppShotsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/app-shots/templates") { _, _ -> Response in
            let repo = ClientProvider.makeTemplateRepository()
            do {
                let output = try await RESTHandlers.listTemplates(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list templates: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/app-shots/themes") { _, _ -> Response in
            let repo = ClientProvider.makeThemeRepository()
            do {
                let output = try await RESTHandlers.listThemes(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list themes: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}

import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Foundation

/// /api/v1/app-shots — Screenshot template, theme, and export routes.
/// All routes proxy to CLI commands via RESTHandlers.
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

        group.post("/app-shots/templates/apply") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                return jsonError("Invalid JSON body")
            }
            do {
                let output = try await RESTHandlers.applyTemplate(json: json)
                return restResponse(output)
            } catch {
                return jsonError("Apply failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.post("/app-shots/themes/apply") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                return jsonError("Invalid JSON body")
            }
            do {
                let output = try await RESTHandlers.applyTheme(json: json)
                return restResponse(output)
            } catch {
                return jsonError("Theme apply failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.post("/app-shots/export") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                return jsonError("Invalid JSON body")
            }
            do {
                let output = try await RESTHandlers.exportHTML(json: json)
                return restResponse(output)
            } catch {
                return jsonError("Export failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.post("/app-shots/generate") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 20 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                return jsonError("Invalid JSON body")
            }
            do {
                let output = try await RESTHandlers.generateAI(json: json)
                return restResponse(output)
            } catch {
                return jsonError("Generate failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}

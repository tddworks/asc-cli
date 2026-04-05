import Domain
import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Foundation

/// /api/v1/app-shots — Screenshot template and theme routes.
enum AppShotsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        // GET /api/v1/app-shots/templates
        group.get("/app-shots/templates") { _, _ -> Response in
            let repo = ClientProvider.makeTemplateRepository()
            do {
                let output = try await RESTHandlers.listTemplates(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list templates: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // GET /api/v1/app-shots/themes
        group.get("/app-shots/themes") { _, _ -> Response in
            let repo = ClientProvider.makeThemeRepository()
            do {
                let output = try await RESTHandlers.listThemes(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list themes: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // POST /api/v1/app-shots/templates/apply
        // Accepts: {templateId, screenshot (base64), headline, subtitle?, preview: "html"|"image"}
        // Returns: HTML string or {exported, width, height, bytes}
        group.post("/app-shots/templates/apply") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let templateId = json["templateId"] as? String,
                  let headline = json["headline"] as? String else {
                return jsonError("Missing templateId or headline")
            }

            let screenshotBase64 = json["screenshot"] as? String
            let subtitle = json["subtitle"] as? String
            let previewFormat = json["preview"] as? String ?? "html"

            do {
                let repo = ClientProvider.makeTemplateRepository()
                guard let template = try await repo.getTemplate(id: templateId) else {
                    return jsonError("Template not found", status: .notFound)
                }

                // Write screenshot to temp file if base64 provided
                var screenshotPath = json["screenshotPath"] as? String ?? ""
                if let b64 = screenshotBase64, let data = Data(base64Encoded: b64) {
                    let tmpDir = FileManager.default.temporaryDirectory
                    let tmpFile = tmpDir.appendingPathComponent("blitz-\(UUID().uuidString).png")
                    try data.write(to: tmpFile)
                    screenshotPath = tmpFile.path
                }

                let content = TemplateContent(
                    headline: headline,
                    subtitle: subtitle,
                    screenshotFile: screenshotPath.isEmpty ? "" : URL(fileURLWithPath: screenshotPath).lastPathComponent
                )

                if previewFormat == "image" {
                    let renderer = ClientProvider.makeHTMLRenderer()
                    let fullContent = TemplateContent(
                        headline: headline,
                        subtitle: subtitle,
                        screenshotFile: screenshotPath
                    )
                    let html = TemplateHTMLRenderer.renderPage(template, content: fullContent, fillViewport: true)
                    let pngData = try await renderer.render(html: html, width: 1320, height: 2868)
                    let b64 = pngData.base64EncodedString()
                    let result = try JSONSerialization.data(
                        withJSONObject: ["png": b64, "width": 1320, "height": 2868],
                        options: [.sortedKeys]
                    )
                    return Response(
                        status: .ok,
                        headers: [.contentType: "application/json"],
                        body: .init(byteBuffer: ByteBuffer(data: result))
                    )
                }

                // HTML preview
                let html = TemplateHTMLRenderer.renderPage(template, content: content)
                let result = try JSONSerialization.data(
                    withJSONObject: ["html": html],
                    options: []
                )
                return Response(
                    status: .ok,
                    headers: [.contentType: "application/json"],
                    body: .init(byteBuffer: ByteBuffer(data: result))
                )
            } catch {
                return jsonError("Apply failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // POST /api/v1/app-shots/themes/apply
        // Accepts: {themeId, templateId, screenshot (base64), headline}
        // Returns: {html: "themed HTML"}
        group.post("/app-shots/themes/apply") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let themeId = json["themeId"] as? String,
                  let templateId = json["templateId"] as? String,
                  let headline = json["headline"] as? String else {
                return jsonError("Missing themeId, templateId, or headline")
            }

            let screenshotBase64 = json["screenshot"] as? String

            do {
                let templateRepo = ClientProvider.makeTemplateRepository()
                let themeRepo = ClientProvider.makeThemeRepository()

                guard let template = try await templateRepo.getTemplate(id: templateId) else {
                    return jsonError("Template not found", status: .notFound)
                }

                // Write screenshot to temp file if base64 provided
                var screenshotPath = json["screenshotPath"] as? String ?? ""
                if let b64 = screenshotBase64, let data = Data(base64Encoded: b64) {
                    let tmpDir = FileManager.default.temporaryDirectory
                    let tmpFile = tmpDir.appendingPathComponent("blitz-\(UUID().uuidString).png")
                    try data.write(to: tmpFile)
                    screenshotPath = tmpFile.path
                }

                let content = TemplateContent(
                    headline: headline,
                    subtitle: json["subtitle"] as? String,
                    screenshotFile: screenshotPath.isEmpty ? "" : URL(fileURLWithPath: screenshotPath).lastPathComponent
                )
                let baseHTML = TemplateHTMLRenderer.renderPage(template, content: content)
                let themedHTML = try await themeRepo.compose(
                    themeId: themeId,
                    html: baseHTML,
                    canvasWidth: json["canvasWidth"] as? Int ?? 1320,
                    canvasHeight: json["canvasHeight"] as? Int ?? 2868
                )

                let result = try JSONSerialization.data(
                    withJSONObject: ["html": themedHTML],
                    options: []
                )
                return Response(
                    status: .ok,
                    headers: [.contentType: "application/json"],
                    body: .init(byteBuffer: ByteBuffer(data: result))
                )
            } catch {
                return jsonError("Theme apply failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}

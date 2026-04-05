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

                if previewFormat == "image" {
                    // Image render: WebKit needs a real file path
                    var screenshotPath = ""
                    if let b64 = screenshotBase64, let data = Data(base64Encoded: b64) {
                        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("blitz-\(UUID().uuidString).png")
                        try data.write(to: tmpFile)
                        screenshotPath = tmpFile.path
                    }
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

                // HTML preview: embed screenshot as data URL so iframe can display it
                let screenshotDataURL = screenshotBase64.map { "data:image/png;base64,\($0)" } ?? ""
                let content = TemplateContent(
                    headline: headline,
                    subtitle: subtitle,
                    screenshotFile: screenshotDataURL
                )
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

                // Screenshot goes to temp file — the Node.js bridge receives HTML via stdin,
                // so embedding a multi-MB base64 data URL would exceed pipe limits.
                // Instead, use a file path in the HTML, let the bridge process it,
                // then replace the path with a data URL in the response for inline iframe display.
                var screenshotRef = "screenshot.png"
                if let b64 = screenshotBase64, let data = Data(base64Encoded: b64) {
                    let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("blitz-\(UUID().uuidString).png")
                    try data.write(to: tmpFile)
                    screenshotRef = tmpFile.path
                }
                let content = TemplateContent(
                    headline: headline,
                    subtitle: json["subtitle"] as? String,
                    screenshotFile: screenshotRef
                )
                let baseHTML = TemplateHTMLRenderer.renderPage(template, content: content)
                var themedHTML = try await themeRepo.compose(
                    themeId: themeId,
                    html: baseHTML,
                    canvasWidth: json["canvasWidth"] as? Int ?? 1320,
                    canvasHeight: json["canvasHeight"] as? Int ?? 2868
                )

                // Replace temp file path with data URL so iframe can display inline
                if let b64 = screenshotBase64 {
                    themedHTML = themedHTML.replacingOccurrences(of: screenshotRef, with: "data:image/png;base64,\(b64)")
                }

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
        // POST /api/v1/app-shots/generate
        // Accepts: {screenshot (base64), geminiApiKey?, styleReference? (base64), deviceType?, prompt?}
        // Returns: {png: base64, width, height}
        group.post("/app-shots/generate") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 20 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let screenshotB64 = json["screenshot"] as? String,
                  let screenshotData = Data(base64Encoded: screenshotB64) else {
                return jsonError("Missing screenshot (base64)")
            }

            do {
                // Resolve API key: request body → config storage → env var
                let apiKey: String
                if let key = json["geminiApiKey"] as? String, !key.isEmpty {
                    apiKey = key
                } else {
                    let configStorage = ClientProvider.makeAppShotsConfigStorage()
                    let config = try? configStorage.load()
                    if let key = config?.geminiApiKey {
                        apiKey = key
                    } else if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
                        apiKey = key
                    } else {
                        return jsonError("No Gemini API key provided. Pass geminiApiKey in request body or set GEMINI_API_KEY env var.")
                    }
                }

                // Write screenshot to temp file (Gemini helper reads from Data, but generate expects file)
                let tmpDir = FileManager.default.temporaryDirectory
                let screenshotFile = tmpDir.appendingPathComponent("blitz-gen-\(UUID().uuidString).png")
                try screenshotData.write(to: screenshotFile)

                // Write style reference to temp file if provided
                var styleRefPath: String? = nil
                if let styleB64 = json["styleReference"] as? String, let styleData = Data(base64Encoded: styleB64) {
                    let styleFile = tmpDir.appendingPathComponent("blitz-style-\(UUID().uuidString).png")
                    try styleData.write(to: styleFile)
                    styleRefPath = styleFile.path
                }

                // Build and run command
                var args = ["--file", screenshotFile.path, "--gemini-api-key", apiKey, "--output-dir", tmpDir.path]
                if let styleRef = styleRefPath { args += ["--style-reference", styleRef] }
                if let deviceType = json["deviceType"] as? String { args += ["--device-type", deviceType] }
                if let prompt = json["prompt"] as? String { args += ["--prompt", prompt] }

                let cmd = try AppShotsGenerate.parse(args)
                _ = try await cmd.execute(apiKey: apiKey)

                // Read the output file
                let outputFile = tmpDir.appendingPathComponent("screen-0.png")
                guard let pngData = FileManager.default.contents(atPath: outputFile.path) else {
                    return jsonError("Generate succeeded but output file not found", status: .internalServerError)
                }

                let resultJSON = try JSONSerialization.data(
                    withJSONObject: ["png": pngData.base64EncodedString(), "width": 1320, "height": 2868],
                    options: [.sortedKeys]
                )
                return Response(
                    status: .ok,
                    headers: [.contentType: "application/json"],
                    body: .init(byteBuffer: ByteBuffer(data: resultJSON))
                )
            } catch {
                return jsonError("Generate failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}

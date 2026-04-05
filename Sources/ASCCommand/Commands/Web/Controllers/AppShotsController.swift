import ArgumentParser
import Domain
import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Foundation

/// /api/v1/app-shots — Screenshot template, theme, and export routes.
/// Read routes delegate to CLI commands. Write routes handle base64 ↔ temp file bridging.
enum AppShotsController {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {

        // MARK: - Read (delegate to commands)

        group.get("/app-shots/templates") { _, _ -> Response in
            try await restExec { try await AppShotsTemplatesList.parse(["--preview", "--pretty"]).execute(repo: ClientProvider.makeTemplateRepository(), affordanceMode: .rest) }
        }

        group.get("/app-shots/themes") { _, _ -> Response in
            try await restExec { try await AppShotsThemesList.parse(["--pretty"]).execute(repo: ClientProvider.makeThemeRepository(), affordanceMode: .rest) }
        }

        // MARK: - Write (base64 ↔ temp file bridging)

        // POST /api/v1/app-shots/templates/apply
        // Accepts: {templateId, screenshot (base64), headline, preview: "html"|"image"}
        group.post("/app-shots/templates/apply") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let templateId = json["templateId"] as? String,
                  let headline = json["headline"] as? String else {
                return jsonError("Missing templateId or headline")
            }
            let screenshotBase64 = json["screenshot"] as? String
            let previewFormat = json["preview"] as? String ?? "html"

            do {
                let screenshotPath = try writeTempScreenshot(screenshotBase64)

                var args = ["--id", templateId, "--screenshot", screenshotPath, "--headline", headline, "--pretty"]
                if let subtitle = json["subtitle"] as? String { args += ["--subtitle", subtitle] }
                if previewFormat == "html" { args += ["--preview", "html"] }
                if previewFormat == "image" { args += ["--preview", "image"] }

                let repo = ClientProvider.makeTemplateRepository()
                let cmd = try AppShotsTemplatesApply.parse(args)

                if previewFormat == "image" {
                    let renderer = ClientProvider.makeHTMLRenderer()
                    guard let tmpl = try await repo.getTemplate(id: templateId) else {
                        return jsonError("Template not found", status: .notFound)
                    }
                    let content = TemplateContent(headline: headline, subtitle: json["subtitle"] as? String, screenshotFile: screenshotPath)
                    let html = TemplateHTMLRenderer.renderPage(tmpl, content: content, fillViewport: true)
                    let pngData = try await AppShotsExport.renderToPNG(html: html, renderer: renderer)
                    return restResponse(jsonEncode(["png": pngData.base64EncodedString(), "width": 1320, "height": 2868]))
                }

                // HTML preview: replace file path with data URL for inline display
                var html = try await cmd.execute(repo: repo)
                if let b64 = screenshotBase64 {
                    let dataURL = "data:image/png;base64,\(b64)"
                    html = html.replacingOccurrences(of: screenshotPath, with: dataURL)
                    html = html.replacingOccurrences(of: URL(fileURLWithPath: screenshotPath).lastPathComponent, with: dataURL)
                }
                return restResponse(jsonEncode(["html": html]))
            } catch {
                return jsonError("Apply failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // POST /api/v1/app-shots/themes/apply
        // Accepts: {themeId, templateId, screenshot (base64), headline}
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
                // Screenshot goes to temp file — the Node.js bridge receives HTML via stdin,
                // so embedding a multi-MB data URL would exceed pipe limits.
                let screenshotPath = try writeTempScreenshot(screenshotBase64)

                var args = ["--theme", themeId, "--template", templateId,
                            "--screenshot", screenshotPath, "--headline", headline, "--pretty"]
                if let subtitle = json["subtitle"] as? String { args += ["--subtitle", subtitle] }

                let cmd = try AppShotsThemesApply.parse(args)
                var themedHTML = try await cmd.execute(
                    themeRepo: ClientProvider.makeThemeRepository(),
                    templateRepo: ClientProvider.makeTemplateRepository()
                )

                // Replace temp file path with data URL so iframe can display inline
                if let b64 = screenshotBase64 {
                    let dataURL = "data:image/png;base64,\(b64)"
                    themedHTML = themedHTML.replacingOccurrences(of: screenshotPath, with: dataURL)
                    themedHTML = themedHTML.replacingOccurrences(of: URL(fileURLWithPath: screenshotPath).lastPathComponent, with: dataURL)
                }
                return restResponse(jsonEncode(["html": themedHTML]))
            } catch {
                return jsonError("Theme apply failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // POST /api/v1/app-shots/export
        // Accepts: {html, width?, height?}  Returns: {png (base64), width, height}
        // Reuses AppShotsExport.renderToPNG() — single source of truth for HTML→PNG.
        group.post("/app-shots/export") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let html = json["html"] as? String else {
                return jsonError("Missing html")
            }
            do {
                let width = json["width"] as? Int ?? 1320
                let height = json["height"] as? Int ?? 2868
                let pngData = try await AppShotsExport.renderToPNG(html: html, width: width, height: height, renderer: ClientProvider.makeHTMLRenderer())
                return restResponse(jsonEncode(["png": pngData.base64EncodedString(), "width": width, "height": height]))
            } catch {
                return jsonError("Export failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // POST /api/v1/app-shots/generate
        // Accepts: {screenshot (base64), geminiApiKey?, styleReference? (base64), prompt?}
        group.post("/app-shots/generate") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 20 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let screenshotB64 = json["screenshot"] as? String,
                  let screenshotData = Data(base64Encoded: screenshotB64) else {
                return jsonError("Missing screenshot (base64)")
            }
            do {
                let apiKey = try resolveGeminiApiKey(json)
                let tmpDir = FileManager.default.temporaryDirectory
                let screenshotFile = tmpDir.appendingPathComponent("blitz-gen-\(UUID().uuidString).png")
                try screenshotData.write(to: screenshotFile)

                var args = ["--file", screenshotFile.path, "--gemini-api-key", apiKey, "--output-dir", tmpDir.path]
                if let deviceType = json["deviceType"] as? String { args += ["--device-type", deviceType] }
                if let prompt = json["prompt"] as? String { args += ["--prompt", prompt] }
                if let styleB64 = json["styleReference"] as? String, let styleData = Data(base64Encoded: styleB64) {
                    let styleFile = tmpDir.appendingPathComponent("blitz-style-\(UUID().uuidString).png")
                    try styleData.write(to: styleFile)
                    args += ["--style-reference", styleFile.path]
                }

                let cmd = try AppShotsGenerate.parse(args)
                _ = try await cmd.execute(apiKey: apiKey)

                let outputFile = tmpDir.appendingPathComponent("screen-0.png")
                guard let pngData = FileManager.default.contents(atPath: outputFile.path) else {
                    return jsonError("Generate succeeded but output not found", status: .internalServerError)
                }
                return restResponse(jsonEncode(["png": pngData.base64EncodedString(), "width": 1320, "height": 2868]))
            } catch {
                return jsonError("Generate failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }

    // MARK: - Helpers

    private static func resolveGeminiApiKey(_ json: [String: Any]) throws -> String {
        if let key = json["geminiApiKey"] as? String, !key.isEmpty { return key }
        if let config = try? ClientProvider.makeAppShotsConfigStorage().load(), !config.geminiApiKey.isEmpty { return config.geminiApiKey }
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] { return key }
        throw ValidationError("No Gemini API key. Pass geminiApiKey or set GEMINI_API_KEY env var.")
    }
}

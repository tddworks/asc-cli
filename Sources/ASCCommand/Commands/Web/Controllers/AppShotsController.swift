import ArgumentParser
import Domain
import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Foundation

/// /api/v1/app-shots — Screenshot template, theme, export, and AI generation.
struct AppShotsController: Sendable {
    let templateRepo: any TemplateRepository
    let themeRepo: any ThemeRepository
    let htmlRenderer: any HTMLRenderer
    let configStorage: any AppShotsConfigStorage
    let galleryTemplateRepo: any GalleryTemplateRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {

        // MARK: - Read

        group.get("/app-shots/templates") { _, _ -> Response in
            let templates = try await self.templateRepo.listTemplates(size: nil)
            return try restFormat(templates)
        }

        group.get("/app-shots/themes") { _, _ -> Response in
            let themes = try await self.themeRepo.listThemes()
            return try restFormat(themes)
        }

        group.get("/app-shots/gallery-templates") { _, _ -> Response in
            let templates = try await self.galleryTemplateRepo.listGalleryTemplates()
            return try restFormat(templates)
        }

        // MARK: - Templates Apply

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
                guard let tmpl = try await self.templateRepo.getTemplate(id: templateId) else {
                    return jsonError("Template not found", status: .notFound)
                }
                let background = Self.parseBackground(json["background"])
                let content = TemplateContent(headline: headline, subtitle: json["subtitle"] as? String, tagline: json["tagline"] as? String, screenshotFile: screenshotPath, background: background, textColor: json["textColor"] as? String)

                if previewFormat == "image" {
                    let html = tmpl.apply(content: content, fillViewport: true)
                    let pngData = try await AppShotsExport.renderToPNG(html: html, renderer: self.htmlRenderer)
                    return restResponse(jsonEncode(["png": pngData.base64EncodedString(), "width": 1320, "height": 2868]))
                }

                var html = tmpl.apply(content: content)
                html = Self.inlineBase64(html, screenshotPath: screenshotPath, base64: screenshotBase64)
                return restResponse(jsonEncode(["html": html]))
            } catch {
                return jsonError("Apply failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // MARK: - Themes Apply

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
                let screenshotPath = try writeTempScreenshot(screenshotBase64)
                guard let tmpl = try await self.templateRepo.getTemplate(id: templateId) else {
                    return jsonError("Template not found", status: .notFound)
                }
                let background = Self.parseBackground(json["background"])
                let content = TemplateContent(headline: headline, subtitle: json["subtitle"] as? String, tagline: json["tagline"] as? String, screenshotFile: screenshotPath, background: background, textColor: json["textColor"] as? String)
                let fragment = tmpl.renderFragment(content: content)
                let themedHTML = try await self.themeRepo.compose(themeId: themeId, html: fragment, canvasWidth: 1320, canvasHeight: 2868)
                var html = ThemedPage(body: themedHTML, width: 1320, height: 2868).html
                html = Self.inlineBase64(html, screenshotPath: screenshotPath, base64: screenshotBase64)
                return restResponse(jsonEncode(["html": html]))
            } catch {
                return jsonError("Theme apply failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // MARK: - Export

        group.post("/app-shots/export") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let html = json["html"] as? String else {
                return jsonError("Missing html")
            }
            do {
                let width = json["width"] as? Int ?? 1320
                let height = json["height"] as? Int ?? 2868
                let pngData = try await AppShotsExport.renderToPNG(html: html, width: width, height: height, renderer: self.htmlRenderer)
                return restResponse(jsonEncode(["png": pngData.base64EncodedString(), "width": width, "height": height]))
            } catch {
                return jsonError("Export failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // MARK: - Generate

        group.post("/app-shots/generate") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 20 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let screenshotB64 = json["screenshot"] as? String,
                  let screenshotData = Data(base64Encoded: screenshotB64) else {
                return jsonError("Missing screenshot (base64)")
            }
            do {
                let apiKey = try Self.resolveGeminiApiKey(json, configStorage: self.configStorage)
                let tmpDir = FileManager.default.temporaryDirectory
                let screenshotFile = tmpDir.appendingPathComponent("blitz-gen-\(UUID().uuidString).png")
                try screenshotData.write(to: screenshotFile)

                var styleFile: String?
                if let styleB64 = json["styleReference"] as? String, let styleData = Data(base64Encoded: styleB64) {
                    let path = tmpDir.appendingPathComponent("blitz-style-\(UUID().uuidString).png")
                    try styleData.write(to: path)
                    styleFile = path.path
                }

                let deviceType = (json["deviceType"] as? String).flatMap { AppShotsDisplayType(rawValue: $0) }
                _ = try await AppShotsGenerate.run(
                    file: screenshotFile.path,
                    apiKey: apiKey,
                    outputDir: tmpDir.path,
                    styleReference: styleFile,
                    deviceType: deviceType,
                    prompt: json["prompt"] as? String
                )

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

    /// Parse a background JSON object into a SlideBackground.
    private static func parseBackground(_ value: Any?) -> SlideBackground? {
        guard let dict = value as? [String: Any],
              let type = dict["type"] as? String else { return nil }
        if type == "gradient",
           let from = dict["from"] as? String,
           let to = dict["to"] as? String {
            let angle = dict["angle"] as? Int ?? 180
            return .gradient(from: from, to: to, angle: angle)
        }
        if let color = dict["color"] as? String {
            return .solid(color)
        }
        return nil
    }

    /// Replace temp file paths with data URLs for inline browser display.
    private static func inlineBase64(_ html: String, screenshotPath: String, base64: String?) -> String {
        guard let b64 = base64 else { return html }
        let dataURL = "data:image/png;base64,\(b64)"
        var result = html.replacingOccurrences(of: screenshotPath, with: dataURL)
        result = result.replacingOccurrences(of: URL(fileURLWithPath: screenshotPath).lastPathComponent, with: dataURL)
        return result
    }

    private static func resolveGeminiApiKey(_ json: [String: Any], configStorage: any AppShotsConfigStorage) throws -> String {
        if let key = json["geminiApiKey"] as? String, !key.isEmpty { return key }
        if let config = try? configStorage.load(), !config.geminiApiKey.isEmpty { return config.geminiApiKey }
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] { return key }
        throw ValidationError("No Gemini API key. Pass geminiApiKey or set GEMINI_API_KEY env var.")
    }
}

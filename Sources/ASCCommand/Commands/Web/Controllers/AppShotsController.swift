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
            let galleries = try await self.galleryTemplateRepo.listGalleries()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(["data": galleries])
            return restResponse(String(data: data, encoding: .utf8) ?? "[]")
        }

        // MARK: - Gallery Compose

        group.post("/app-shots/gallery/compose") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 50 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let templateId = json["templateId"] as? String,
                  let screenshotsB64 = json["screenshots"] as? [String] else {
                return jsonError("Missing templateId or screenshots array")
            }

            do {
                guard let sampleGallery = try await self.galleryTemplateRepo.getGallery(templateId: templateId) else {
                    return jsonError("Gallery template not found", status: .notFound)
                }

                // Write screenshots to temp and build data URL map
                var paths: [String] = []
                var dataURLs: [String: String] = [:]
                for (i, b64) in screenshotsB64.enumerated() {
                    guard let data = Data(base64Encoded: b64) else { continue }
                    let path = FileManager.default.temporaryDirectory
                        .appendingPathComponent("gallery-\(UUID().uuidString)-\(i).png")
                    try data.write(to: path)
                    paths.append(path.path)
                    dataURLs[path.path] = "data:image/png;base64,\(b64)"
                }

                // Domain does the work
                let gallery = sampleGallery.applyScreenshots(paths)

                // Override with AI-generated headlines if provided
                if let headlines = json["headlines"] as? [[String: Any]] {
                    for (i, h) in headlines.enumerated() where i < gallery.appShots.count {
                        if let headline = h["headline"] as? String, !headline.isEmpty {
                            gallery.appShots[i].headline = headline
                        }
                        if let tagline = h["tagline"] as? String, !tagline.isEmpty {
                            gallery.appShots[i].tagline = tagline
                        }
                        if let body = h["body"] as? String, !body.isEmpty {
                            gallery.appShots[i].body = body
                        }
                    }
                }

                let pages = gallery.renderAll().map { html in
                    var inlined = html
                    for (path, url) in dataURLs { inlined = inlined.replacingOccurrences(of: path, with: url) }
                    return GalleryHTMLRenderer.wrapPage(inlined)
                }

                return restResponse(jsonEncode(["screens": pages]))
            } catch {
                return jsonError("Gallery compose failed: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // MARK: - Templates Apply

        group.post("/app-shots/templates/apply") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let templateId = json["templateId"] as? String,
                  let headline = json["headline"] as? String else {
                return jsonError("Missing templateId or headline")
            }
            let previewFormat = json["preview"] as? String ?? "html"
            // Support both single "screenshot" and multi "screenshots"
            let screenshotsB64: [String]
            if let arr = json["screenshots"] as? [String] {
                screenshotsB64 = arr
            } else if let single = json["screenshot"] as? String {
                screenshotsB64 = [single]
            } else {
                screenshotsB64 = []
            }

            do {
                // Write each screenshot to temp and build data URL map
                var paths: [String] = []
                var dataURLs: [String: String] = [:]
                for (i, b64) in screenshotsB64.enumerated() {
                    guard let data = Data(base64Encoded: b64) else { continue }
                    let path = FileManager.default.temporaryDirectory
                        .appendingPathComponent("tmpl-\(UUID().uuidString)-\(i).png")
                    try data.write(to: path)
                    paths.append(path.path)
                    dataURLs[path.path] = "data:image/png;base64,\(b64)"
                }

                let shot = AppShot(screenshots: paths, type: .feature)
                shot.headline = headline
                shot.body = json["subtitle"] as? String
                shot.tagline = json["tagline"] as? String

                // Resolve screenLayout + palette from single or gallery template
                let screenLayout: ScreenLayout
                let palette: GalleryPalette
                if let tmpl = try await self.templateRepo.getTemplate(id: templateId) {
                    screenLayout = tmpl.screenLayout
                    palette = tmpl.palette
                } else if let gallery = try await self.galleryTemplateRepo.getGallery(templateId: templateId),
                          let tmpl = gallery.template,
                          let p = gallery.palette {
                    screenLayout = tmpl.screens[.feature] ?? tmpl.screens[.hero] ?? ScreenLayout(headline: TextSlot(y: 0.04, size: 0.10))
                    palette = p
                } else {
                    return jsonError("Template not found", status: .notFound)
                }

                let renderHTML = { (fillViewport: Bool) -> String in
                    let html = GalleryHTMLRenderer.renderScreen(shot, screenLayout: screenLayout, palette: palette)
                    return GalleryHTMLRenderer.wrapPage(html, fillViewport: fillViewport)
                }

                if previewFormat == "image" {
                    let html = renderHTML(true)
                    let pngData = try await AppShotsExport.renderToPNG(html: html, renderer: self.htmlRenderer)
                    return restResponse(jsonEncode(["png": pngData.base64EncodedString(), "width": 1320, "height": 2868]))
                }

                var html = renderHTML(false)
                for (path, url) in dataURLs { html = html.replacingOccurrences(of: path, with: url) }
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

                let shot = AppShot(screenshot: screenshotPath, type: .feature)
                shot.headline = headline
                shot.body = json["subtitle"] as? String
                shot.tagline = json["tagline"] as? String

                guard let tmpl = try await self.templateRepo.getTemplate(id: templateId) else {
                    return jsonError("Template not found", status: .notFound)
                }
                let fragment = tmpl.renderFragment(shot: shot)

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

import ArgumentParser
import Domain
import Foundation
import Infrastructure

/// REST API handlers that reuse CLI command `execute()` methods.
///
/// Each handler constructs a command via `parse()`, injects the repository,
/// and calls `execute(repo:, affordanceMode: .rest)`. Zero duplication —
/// the command owns the fetch + format logic, REST just sets the mode.
enum RESTHandlers {

    private static let formatter = OutputFormatter(format: .json, pretty: true)

    // MARK: - API Root

    static func apiRoot() throws -> String {
        let root = APIRoot()
        return try formatter.formatAgentItems(
            [root],
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Apps

    static func listApps(repo: any AppRepository, limit: Int? = nil) async throws -> String {
        let cmd = try AppsList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func getApp(id: String, repo: any AppRepository) async throws -> String {
        // No CLI command for single app get — format directly
        let app = try await repo.getApp(id: id)
        return try formatter.formatAgentItems(
            [app],
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Versions

    static func listVersions(appId: String, repo: any VersionRepository) async throws -> String {
        let cmd = try VersionsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Builds

    static func listBuilds(appId: String, repo: any BuildRepository) async throws -> String {
        let cmd = try BuildsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - TestFlight

    static func listBetaGroups(appId: String, repo: any TestFlightRepository) async throws -> String {
        let cmd = try BetaGroupsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Reviews

    static func listReviews(appId: String, repo: any CustomerReviewRepository) async throws -> String {
        let cmd = try ReviewsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - IAP

    static func listIAP(appId: String, repo: any InAppPurchaseRepository) async throws -> String {
        let cmd = try IAPList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Subscriptions

    static func listSubscriptionGroups(appId: String, repo: any SubscriptionGroupRepository) async throws -> String {
        let cmd = try SubscriptionGroupsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Simulators

    static func listSimulators(repo: any SimulatorRepository) async throws -> String {
        let cmd = try SimulatorsList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Code Signing

    static func listCertificates(repo: any CertificateRepository) async throws -> String {
        let cmd = try CertificatesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listBundleIDs(repo: any BundleIDRepository) async throws -> String {
        let cmd = try BundleIDsList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listDevices(repo: any DeviceRepository) async throws -> String {
        let cmd = try DevicesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listProfiles(repo: any ProfileRepository) async throws -> String {
        let cmd = try ProfilesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Plugins

    static func listPlugins(repo: any PluginRepository) async throws -> String {
        let cmd = try PluginsList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listMarketPlugins(repo: any PluginRepository) async throws -> String {
        let cmd = try MarketList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - App Shots

    static func listTemplates(repo: any TemplateRepository) async throws -> String {
        let cmd = try AppShotsTemplatesList.parse(["--preview", "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listThemes(repo: any ThemeRepository) async throws -> String {
        let cmd = try AppShotsThemesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    /// Apply template: writes base64 screenshot to temp file, delegates to AppShotsTemplatesApply.
    /// For HTML preview: replaces file path with data URL in output.
    /// For image render: returns base64 PNG.
    static func applyTemplate(json: [String: Any]) async throws -> String {
        guard let templateId = json["templateId"] as? String,
              let headline = json["headline"] as? String else {
            throw ValidationError("Missing templateId or headline")
        }
        let screenshotBase64 = json["screenshot"] as? String
        let previewFormat = json["preview"] as? String ?? "html"

        // Write screenshot to temp file (command expects a file path)
        let screenshotPath = try writeTempScreenshot(screenshotBase64)

        var args = ["--id", templateId, "--screenshot", screenshotPath, "--headline", headline, "--pretty"]
        if let subtitle = json["subtitle"] as? String { args += ["--subtitle", subtitle] }
        if previewFormat == "html" { args += ["--preview", "html"] }
        if previewFormat == "image" { args += ["--preview", "image", "--image-output", "/dev/null"] }

        let repo = ClientProvider.makeTemplateRepository()
        let cmd = try AppShotsTemplatesApply.parse(args)

        if previewFormat == "image" {
            let renderer = ClientProvider.makeHTMLRenderer()
            let output = try await cmd.execute(repo: repo, renderer: renderer)
            // Command wrote to /dev/null, but we want base64 — re-render
            guard let tmpl = try await repo.getTemplate(id: templateId) else {
                throw ValidationError("Template not found")
            }
            let content = TemplateContent(headline: headline, subtitle: json["subtitle"] as? String, screenshotFile: screenshotPath)
            let html = TemplateHTMLRenderer.renderPage(tmpl, content: content, fillViewport: true)
            let pngData = try await AppShotsExport.renderToPNG(html: html, renderer: renderer)
            return jsonEncode(["png": pngData.base64EncodedString(), "width": 1320, "height": 2868])
        }

        // HTML preview: replace file path with data URL for inline display
        var html = try await cmd.execute(repo: repo)
        if let b64 = screenshotBase64 {
            html = html.replacingOccurrences(of: screenshotPath, with: "data:image/png;base64,\(b64)")
            html = html.replacingOccurrences(of: URL(fileURLWithPath: screenshotPath).lastPathComponent, with: "data:image/png;base64,\(b64)")
        }
        return jsonEncode(["html": html])
    }

    /// Apply theme: writes base64 screenshot to temp file, delegates to AppShotsThemesApply.
    /// Replaces file path with data URL in output for inline iframe display.
    static func applyTheme(json: [String: Any]) async throws -> String {
        guard let themeId = json["themeId"] as? String,
              let templateId = json["templateId"] as? String,
              let headline = json["headline"] as? String else {
            throw ValidationError("Missing themeId, templateId, or headline")
        }
        let screenshotBase64 = json["screenshot"] as? String

        // Screenshot goes to temp file — the Node.js bridge receives HTML via stdin,
        // so embedding a multi-MB data URL would exceed pipe limits.
        let screenshotPath = try writeTempScreenshot(screenshotBase64)

        var args = ["--theme", themeId, "--template", templateId,
                    "--screenshot", screenshotPath, "--headline", headline, "--pretty"]
        if let subtitle = json["subtitle"] as? String { args += ["--subtitle", subtitle] }

        let themeRepo = ClientProvider.makeThemeRepository()
        let templateRepo = ClientProvider.makeTemplateRepository()
        let cmd = try AppShotsThemesApply.parse(args)
        var themedHTML = try await cmd.execute(themeRepo: themeRepo, templateRepo: templateRepo)

        // Replace temp file path with data URL so iframe can display inline
        if let b64 = screenshotBase64 {
            themedHTML = themedHTML.replacingOccurrences(of: screenshotPath, with: "data:image/png;base64,\(b64)")
            themedHTML = themedHTML.replacingOccurrences(of: URL(fileURLWithPath: screenshotPath).lastPathComponent, with: "data:image/png;base64,\(b64)")
        }
        return jsonEncode(["html": themedHTML])
    }

    /// Export HTML to PNG: delegates to AppShotsExport.renderToPNG().
    static func exportHTML(json: [String: Any]) async throws -> String {
        guard let html = json["html"] as? String else {
            throw ValidationError("Missing html")
        }
        let width = json["width"] as? Int ?? 1320
        let height = json["height"] as? Int ?? 2868
        let renderer = ClientProvider.makeHTMLRenderer()
        let pngData = try await AppShotsExport.renderToPNG(html: html, width: width, height: height, renderer: renderer)
        return jsonEncode(["png": pngData.base64EncodedString(), "width": width, "height": height])
    }

    /// AI enhance via Gemini: delegates to AppShotsGenerate.
    static func generateAI(json: [String: Any]) async throws -> String {
        guard let screenshotB64 = json["screenshot"] as? String,
              let screenshotData = Data(base64Encoded: screenshotB64) else {
            throw ValidationError("Missing screenshot (base64)")
        }

        let configStorage = ClientProvider.makeAppShotsConfigStorage()
        let apiKey: String
        if let key = json["geminiApiKey"] as? String, !key.isEmpty {
            apiKey = key
        } else if let config = try? configStorage.load() {
            let key = config.geminiApiKey
            guard !key.isEmpty else { throw ValidationError("Gemini API key is empty in config") }
            apiKey = key
        } else if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            apiKey = key
        } else {
            throw ValidationError("No Gemini API key. Pass geminiApiKey or set GEMINI_API_KEY env var.")
        }

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
            throw ValidationError("Generate succeeded but output file not found")
        }
        return jsonEncode(["png": pngData.base64EncodedString(), "width": 1320, "height": 2868])
    }

    // MARK: - Helpers

    private static func writeTempScreenshot(_ base64: String?) throws -> String {
        guard let b64 = base64, let data = Data(base64Encoded: b64) else {
            return "screenshot.png"
        }
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("blitz-\(UUID().uuidString).png")
        try data.write(to: tmpFile)
        return tmpFile.path
    }

    private static func jsonEncode(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - Territories

    static func listTerritories(repo: any TerritoryRepository) async throws -> String {
        let cmd = try TerritoriesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }
}

import ArgumentParser
import Domain
import Foundation

struct ScreenshotsImport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import screenshots from an exported ZIP file"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version ID")
    var versionId: String

    @Option(name: .long, help: "Path to export.zip from the screenshot editor")
    var from: String

    func run() async throws {
        let (manifest, imageURLs, tempDir) = try unzipAndParse(from: from)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let localizationRepo = try ClientProvider.makeVersionLocalizationRepository()
        let screenshotRepo = try ClientProvider.makeScreenshotRepository()
        print(try await execute(localizationRepo: localizationRepo, screenshotRepo: screenshotRepo, manifest: manifest, imageURLs: imageURLs))
    }

    // MARK: - Testable core (no I/O)

    func execute(
        localizationRepo: any VersionLocalizationRepository,
        screenshotRepo: any ScreenshotRepository,
        manifest: ScreenshotManifest,
        imageURLs: [String: URL]
    ) async throws -> String {
        var results: [AppScreenshot] = []

        let existingLocalizations = try await localizationRepo.listLocalizations(versionId: versionId)
        for (locale, locManifest) in manifest.localizations.sorted(by: { $0.key < $1.key }) {
            // Find or create localization
            let localization: AppStoreVersionLocalization
            if let existing = existingLocalizations.first(where: { $0.locale == locale }) {
                localization = existing
            } else {
                localization = try await localizationRepo.createLocalization(versionId: versionId, locale: locale)
            }

            // Find or create screenshot set — set comes with repo already injected
            let sets = try await screenshotRepo.listScreenshotSets(localizationId: localization.id)
            let set: AppScreenshotSet
            if let existing = sets.first(where: { $0.screenshotDisplayType == locManifest.displayType }) {
                set = existing
            } else {
                set = try await screenshotRepo.createScreenshotSet(localizationId: localization.id, displayType: locManifest.displayType)
            }

            // Domain operation: set uploads its own entries in order
            let screenshots = try await set.importScreenshots(
                entries: locManifest.screenshots,
                imageURLs: imageURLs
            )
            results.append(contentsOf: screenshots)
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            results,
            headers: ["ID", "File Name", "Size", "State"],
            rowMapper: { [
                $0.id,
                $0.fileName,
                $0.fileSizeDescription,
                $0.assetState?.displayName ?? "-",
            ] }
        )
    }

    // MARK: - I/O (only called from run())

    private func unzipAndParse(from path: String) throws -> (ScreenshotManifest, [String: URL], URL) {
        let zipURL = URL(fileURLWithPath: path)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-import-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", zipURL.path, "-d", tempDir.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw ValidationError("Failed to unzip \(path)")
        }

        let manifestData = try Data(contentsOf: tempDir.appendingPathComponent("manifest.json"))
        let manifest = try JSONDecoder().decode(ScreenshotManifest.self, from: manifestData)

        // Pre-resolve all image URLs so execute() needs no filesystem knowledge
        var imageURLs: [String: URL] = [:]
        for locManifest in manifest.localizations.values {
            for entry in locManifest.screenshots {
                imageURLs[entry.file] = tempDir.appendingPathComponent(entry.file)
            }
        }

        return (manifest, imageURLs, tempDir)
    }
}

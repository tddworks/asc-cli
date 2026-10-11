import ArgumentParser
import Domain
import Foundation

extension ExistingScreenshotsPolicy: ExpressibleByArgument {}

/// What `asc screenshots import --to-library` printed, and whether every group made it.
struct ScreenshotImportReport: Sendable, Equatable {
    let output: String
    let isSuccess: Bool
}

struct ScreenshotsImport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import screenshots from an exported ZIP file",
        discussion: """
        Without --to-library, screenshots go into screenshot sets, which App Store Connect API 4.5.1 deprecates. \
        With --to-library, they're uploaded once into the app's asset library and placed on each localization \
        in the placement group their exact pixel size matches.
        """
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version ID")
    var versionId: String

    @Option(name: .long, help: "Path to export.zip from the screenshot editor")
    var from: String

    @Flag(name: .long, help: "Upload into the app's asset library and place on each localization (instead of deprecated screenshot sets)")
    var toLibrary: Bool = false

    @Option(name: .long, help: "With --to-library: what to do with screenshots already in a group — fail (default), replace or append.")
    var existing: ExistingScreenshotsPolicy?

    @Option(name: .long, help: "With --to-library: the placement group for sizes that fit several (repeatable)")
    var placementGroup: [String] = []

    @Flag(name: .long, help: "With --to-library: show the plan without uploading or changing anything")
    var dryRun: Bool = false

    func validate() throws {
        if !toLibrary, existing != nil || !placementGroup.isEmpty || dryRun {
            throw ValidationError("--existing, --placement-group and --dry-run only apply with --to-library")
        }
    }

    func run() async throws {
        let (manifest, imageURLs, tempDir) = try Self.unzipAndParse(zipURL: URL(fileURLWithPath: from))
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let localizationRepo = try ClientProvider.makeVersionLocalizationRepository()

        guard toLibrary else {
            FileHandle.standardError.write(Data((
                "Note: screenshot sets are deprecated in App Store Connect API 4.5.1 — "
                + "add --to-library to import into the app's asset library instead.\n"
            ).utf8))
            let screenshotRepo = try ClientProvider.makeScreenshotRepository()
            print(try await execute(localizationRepo: localizationRepo, screenshotRepo: screenshotRepo, manifest: manifest, imageURLs: imageURLs))
            return
        }

        let report = try await executeToLibrary(
            manifest: manifest,
            files: try ScreenshotImportFiles.read(manifest: manifest, imageURLs: imageURLs),
            versionRepo: try ClientProvider.makeVersionRepository(),
            localizationRepo: localizationRepo,
            libraryRepo: try ClientProvider.makeAssetLibraryRepository(),
            imageRepo: try ClientProvider.makeLibraryImageRepository(),
            placementRepo: try ClientProvider.makeAssetPlacementRepository()
        )
        print(report.output)
        if !report.isSuccess { throw ExitCode.failure }
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

    /// `--to-library`: plans which placement group each screenshot fills, then (unless
    /// `--dry-run`) adds missing locales, uploads, waits for processing, places and orders.
    func executeToLibrary(
        manifest: ScreenshotManifest,
        files: [ScreenshotImportFile],
        versionRepo: any VersionRepository,
        localizationRepo: any VersionLocalizationRepository,
        libraryRepo: any AssetLibraryRepository,
        imageRepo: any LibraryImageRepository,
        placementRepo: any AssetPlacementRepository,
        affordanceMode: AffordanceMode = .cli,
        sleep: @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }
    ) async throws -> ScreenshotImportReport {
        let version = try await versionRepo.getVersion(id: versionId)
        guard version.isEditable else {
            throw ValidationError(
                "Version \(version.versionString) is \(version.state.rawValue) — screenshots can only change while the version is editable"
            )
        }
        let library = try await libraryRepo.getAssetLibrary(appId: version.appId)
        let groups = try await libraryRepo.listPlacementGroups(placementType: .appScreenshot, feature: "APP_STORE_VERSIONS")

        var localizations = try await localizationRepo.listLocalizations(versionId: versionId)
        if !dryRun {
            for locale in manifest.localizations.keys.sorted() where !localizations.contains(where: { $0.locale == locale }) {
                localizations.append(try await localizationRepo.createLocalization(versionId: versionId, locale: locale))
            }
        }

        var existingPlacements: [AssetPlacement] = []
        for localization in localizations where manifest.localizations[localization.locale] != nil {
            existingPlacements += try await placementRepo.listPlacements(
                surface: .appStoreVersionLocalization, localizationId: localization.id,
                placementType: .appScreenshot, placementGroup: nil
            )
        }

        let plan = ScreenshotImportPlan.plan(
            manifest: manifest, files: files, groups: groups, localizations: localizations,
            existing: existingPlacements, overrides: placementGroup, policy: existing ?? .fail
        )
        let results = dryRun
            ? plan.results
            : await plan.execute(libraryId: library.id, imageRepo: imageRepo, placementRepo: placementRepo, sleep: sleep)

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return ScreenshotImportReport(
            output: try formatter.formatAgentItems(results, affordanceMode: affordanceMode),
            isSuccess: results.allSatisfy(\.status.isSuccess)
        )
    }

    // MARK: - I/O

    /// Extracts the export ZIP into a temp directory; the caller removes the directory.
    static func unzipAndParse(zipURL: URL) throws -> (ScreenshotManifest, [String: URL], URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-import-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", zipURL.path, "-d", tempDir.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw ValidationError("Failed to unzip \(zipURL.path)")
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

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
        let repo = try ClientProvider.makeScreenshotRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ScreenshotRepository) async throws -> String {
        let zipURL = URL(fileURLWithPath: from)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-import-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Unzip
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", zipURL.path, "-d", tempDir.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw ValidationError("Failed to unzip \(from)")
        }

        // Parse manifest
        let manifestURL = tempDir.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(ScreenshotManifest.self, from: manifestData)

        // Import
        let results = try await repo.importScreenshots(
            versionId: versionId,
            manifest: manifest,
            zipDirectory: tempDir
        )

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
}

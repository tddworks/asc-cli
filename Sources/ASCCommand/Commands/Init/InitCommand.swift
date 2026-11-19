import ArgumentParser
import ASCKit
import Foundation

struct InitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialise project context — saves app ID to .asc/project.json"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store Connect app ID")
    var appId: String?

    @Option(name: .long, help: "App name to search for")
    var name: String?

    @Option(name: .long, help: "Review contact first name")
    var contactFirstName: String?

    @Option(name: .long, help: "Review contact last name")
    var contactLastName: String?

    @Option(name: .long, help: "Review contact phone number")
    var contactPhone: String?

    @Option(name: .long, help: "Review contact email address")
    var contactEmail: String?

    func run() async throws {
        let repo = try ClientProvider.makeAppRepository()
        let storage = ClientProvider.makeProjectConfigStorage()
        print(try await execute(repo: repo, storage: storage))
    }

    func execute(
        repo: any AppRepository,
        storage: any ProjectConfigStorage,
        bundleIdScanner: (String) -> [String] = { XcodeProjectScanner.scan(directory: $0) }
    ) async throws -> String {
        let config: ProjectConfig

        let app: App
        if let appId {
            app = try await repo.getApp(id: appId)
        } else if let name {
            let apps = try await repo.listApps(limit: nil).data
            guard let found = apps.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
                throw ValidationError("No app named '\(name)'. Run `asc apps list` to see available apps.")
            }
            app = found
        } else {
            let bundleIds = bundleIdScanner(FileManager.default.currentDirectoryPath)
            guard !bundleIds.isEmpty else {
                throw ValidationError("No Xcode project found. Use --app-id or --name.")
            }
            let apps = try await repo.listApps(limit: nil).data
            guard let found = apps.first(where: { bundleIds.contains($0.bundleId) }) else {
                throw ValidationError("No ASC app matched bundle IDs: \(bundleIds.joined(separator: ", "))")
            }
            app = found
        }

        config = ProjectConfig(
            appId: app.id,
            appName: app.name,
            bundleId: app.bundleId,
            contactFirstName: contactFirstName,
            contactLastName: contactLastName,
            contactPhone: contactPhone,
            contactEmail: contactEmail
        )

        try storage.save(config)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [config],
            headers: ["App ID", "Name", "Bundle ID"],
            rowMapper: { [$0.appId, $0.appName, $0.bundleId] }
        )
    }
}

private enum XcodeProjectScanner {
    /// Returns all literal PRODUCT_BUNDLE_IDENTIFIER values found in
    /// *.xcodeproj/project.pbxproj files under `path`.
    static func scan(directory path: String) -> [String] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return [] }
        var bundleIds: [String] = []
        for entry in contents where entry.hasSuffix(".xcodeproj") {
            let pbxprojPath = (path as NSString)
                .appendingPathComponent(entry)
                .appending("/project.pbxproj")
            guard let content = try? String(contentsOfFile: pbxprojPath, encoding: .utf8) else { continue }
            guard let regex = try? NSRegularExpression(pattern: #"PRODUCT_BUNDLE_IDENTIFIER = ([A-Za-z0-9._\-]+);"#) else { continue }
            let range = NSRange(content.startIndex..., in: content)
            for match in regex.matches(in: content, range: range) {
                if let captureRange = Range(match.range(at: 1), in: content) {
                    let bundleId = String(content[captureRange])
                    if !bundleId.contains("$") && !bundleIds.contains(bundleId) {
                        bundleIds.append(bundleId)
                    }
                }
            }
        }
        return bundleIds
    }
}

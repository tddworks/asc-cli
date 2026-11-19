import ArgumentParser
import ASCKit

struct BundleIDsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Register a new bundle identifier"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Display name for the bundle ID")
    var name: String

    @Option(name: .long, help: "Bundle identifier string (e.g. com.example.app)")
    var identifier: String

    @Option(name: .long, help: "Platform: ios, macos, or universal")
    var platform: String

    func run() async throws {
        let repo = try ClientProvider.makeBundleIDRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BundleIDRepository) async throws -> String {
        guard let domainPlatform = BundleIDPlatform(cliArgument: platform) else {
            throw ValidationError("Invalid platform '\(platform)'. Use ios, macos, or universal.")
        }
        let item = try await repo.createBundleID(name: name, identifier: identifier, platform: domainPlatform)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Name", "Identifier", "Platform"],
            rowMapper: { [$0.id, $0.name, $0.identifier, $0.platform.displayName] }
        )
    }
}

import ArgumentParser
import Domain

struct BundleIDsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List bundle identifiers"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by platform (ios, macos, universal)")
    var platform: String?

    @Option(name: .long, help: "Filter by bundle identifier string (e.g. com.example.app)")
    var identifier: String?

    func run() async throws {
        let repo = try ClientProvider.makeBundleIDRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BundleIDRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let domainPlatform = platform.flatMap { BundleIDPlatform(cliArgument: $0) }
        let items = try await repo.listBundleIDs(platform: domainPlatform, identifier: identifier)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            items,
            headers: ["ID", "Name", "Identifier", "Platform"],
            rowMapper: { [$0.id, $0.name, $0.identifier, $0.platform.displayName] },
            affordanceMode: affordanceMode
        )
    }
}

import ArgumentParser
import ASCKit

struct IrisAppsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App name")
    var name: String

    @Option(name: .long, help: "Bundle identifier (e.g. com.example.app)")
    var bundleId: String

    @Option(name: .long, help: "SKU identifier")
    var sku: String

    @Option(name: .long, help: "Primary locale (e.g. en-US)")
    var primaryLocale: String = "en-US"

    @Option(name: .long, help: "Platforms (e.g. IOS, MAC_OS)")
    var platforms: [String] = ["IOS"]

    @Option(name: .long, help: "Initial version string (e.g. 1.0)")
    var version: String = "1.0"

    func run() async throws {
        let cookieProvider = ClientProvider.makeIrisCookieProvider()
        let repo = ClientProvider.makeIrisAppBundles()
        print(try await execute(cookieProvider: cookieProvider, repo: repo))
    }

    func execute(
        cookieProvider: any IrisCookieProvider,
        repo: any IrisAppBundles
    ) async throws -> String {
        let session = try cookieProvider.resolveSession()
        let app = try await repo.createApp(
            session: session,
            name: name,
            bundleId: bundleId,
            sku: sku,
            primaryLocale: primaryLocale,
            platforms: platforms,
            versionString: version
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [app],
            headers: ["ID", "Name", "Bundle ID", "SKU", "Platforms"],
            rowMapper: { [$0.id, $0.name, $0.bundleId, $0.sku, $0.platforms.joined(separator: ",")] }
        )
    }
}

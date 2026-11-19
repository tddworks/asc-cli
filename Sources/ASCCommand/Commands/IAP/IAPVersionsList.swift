import ArgumentParser
import ASCKit

struct IAPVersionsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List review versions of an in-app purchase (add a submittable one to a review submission)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    func run() async throws {
        let repo = try ClientProvider.makeProductVersionRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any ProductVersionRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let versions = try await repo.listInAppPurchaseVersions(iapId: iapId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(versions, affordanceMode: affordanceMode)
    }
}

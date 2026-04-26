import ArgumentParser
import Domain

struct PromotedPurchasesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List promoted purchase slots for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Max results")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makePromotedPurchaseRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any PromotedPurchaseRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let response = try await repo.listPromotedPurchases(appId: appId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data, affordanceMode: affordanceMode)
    }
}

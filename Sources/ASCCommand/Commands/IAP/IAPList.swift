import ArgumentParser
import Domain

struct IAPList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List in-app purchases for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID to list IAPs for")
    var appId: String

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let response = try await repo.listInAppPurchases(appId: appId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data, affordanceMode: affordanceMode)
    }
}

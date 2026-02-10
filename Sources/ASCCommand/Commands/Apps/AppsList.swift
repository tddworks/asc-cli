import ArgumentParser
import Domain

struct AppsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all apps"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Maximum number of apps to return")
    var limit: Int?

    func run() async throws {
        let repos = try ClientProvider.makeRepositories()
        let response = try await repos.apps.listApps(limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)

        let output = try formatter.formatItems(
            response.data,
            headers: ["ID", "Name", "Bundle ID", "SKU"],
            rowMapper: { app in
                [app.id, app.displayName, app.bundleId, app.sku ?? "-"]
            }
        )
        print(output)
    }
}

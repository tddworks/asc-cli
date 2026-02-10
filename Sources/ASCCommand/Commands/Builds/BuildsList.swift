import ArgumentParser
import Domain

struct BuildsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List builds"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by app ID")
    var app: String?

    @Option(name: .long, help: "Maximum number of builds to return")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeBuildRepository()
        let response = try await repo.listBuilds(appId: app, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)

        let output = try formatter.formatItems(
            response.data,
            headers: ["ID", "Version", "State", "Expired"],
            rowMapper: { build in
                [build.id, build.version, build.processingState.rawValue, build.expired ? "Yes" : "No"]
            }
        )
        print(output)
    }
}

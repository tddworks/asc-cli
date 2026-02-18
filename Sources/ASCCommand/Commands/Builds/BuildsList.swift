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
        print(try await execute(repo: repo))
    }

    func execute(repo: any BuildRepository) async throws -> String {
        let response = try await repo.listBuilds(appId: app, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatItems(
            response.data,
            headers: ["ID", "Version", "State", "Expired"],
            rowMapper: { [$0.id, $0.version, $0.processingState.rawValue, $0.expired ? "Yes" : "No"] }
        )
    }
}

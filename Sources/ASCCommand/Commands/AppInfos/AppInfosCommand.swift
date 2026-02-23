import ArgumentParser
import Domain

struct AppInfosCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-infos",
        abstract: "Manage App Store app info",
        subcommands: [AppInfosList.self]
    )
}

struct AppInfosList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List app infos for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppInfoRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppInfoRepository) async throws -> String {
        let infos = try await repo.listAppInfos(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            infos,
            headers: ["ID", "App ID"],
            rowMapper: { [$0.id, $0.appId] }
        )
    }
}

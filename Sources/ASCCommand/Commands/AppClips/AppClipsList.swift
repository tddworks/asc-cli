import ArgumentParser
import Domain

struct AppClipsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List App Clips for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppClipRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppClipRepository) async throws -> String {
        let clips = try await repo.listAppClips(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(clips)
    }
}

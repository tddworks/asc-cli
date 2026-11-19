import ArgumentParser
import ASCKit

struct AppClipExperiencesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List default experiences for an App Clip"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Clip ID")
    var appClipId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppClips()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppClips) async throws -> String {
        let experiences = try await repo.listExperiences(appClipId: appClipId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(experiences)
    }
}

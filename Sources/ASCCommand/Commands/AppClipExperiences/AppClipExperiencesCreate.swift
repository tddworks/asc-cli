import ArgumentParser
import ASCKit

struct AppClipExperiencesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a default experience for an App Clip"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Clip ID")
    var appClipId: String

    @Option(name: .long, help: "Action: OPEN, VIEW, or PLAY")
    var action: String?

    func run() async throws {
        let repo = try ClientProvider.makeAppClipRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppClipRepository) async throws -> String {
        let parsedAction = try resolveAction()
        let experience = try await repo.createExperience(appClipId: appClipId, action: parsedAction)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [experience],
            headers: ["ID", "App Clip ID", "Action"],
            rowMapper: { [$0.id, $0.appClipId, $0.action?.rawValue ?? ""] }
        )
    }

    private func resolveAction() throws -> AppClipAction? {
        guard let action else { return nil }
        guard let parsed = AppClipAction(rawValue: action.uppercased()) else {
            throw ValidationError("Invalid action '\(action)'. Valid values: OPEN, VIEW, PLAY")
        }
        return parsed
    }
}

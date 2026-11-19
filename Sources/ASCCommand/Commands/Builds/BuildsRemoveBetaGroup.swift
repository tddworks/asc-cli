import ArgumentParser
import ASCKit

struct BuildsRemoveBetaGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove-beta-group",
        abstract: "Remove a beta group from a build"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build ID")
    var buildId: String

    @Option(name: .long, help: "Beta group ID")
    var betaGroupId: String

    func run() async throws {
        let repo = try ClientProvider.makeBuilds()
        try await execute(repo: repo)
    }

    func execute(repo: any Builds) async throws {
        try await repo.removeBetaGroups(buildId: buildId, betaGroupIds: [betaGroupId])
    }
}

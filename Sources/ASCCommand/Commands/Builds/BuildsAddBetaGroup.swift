import ArgumentParser
import Domain

struct BuildsAddBetaGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add-beta-group",
        abstract: "Add a beta group to a build for TestFlight distribution"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build ID")
    var buildId: String

    @Option(name: .long, help: "Beta group ID")
    var betaGroupId: String

    func run() async throws {
        let repo = try ClientProvider.makeBuildRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any BuildRepository) async throws {
        try await repo.addBetaGroups(buildId: buildId, betaGroupIds: [betaGroupId])
    }
}

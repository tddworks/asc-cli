import ArgumentParser
import Domain

struct VersionsSetBuild: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-build",
        abstract: "Link a build to an App Store version before submission"
    )

    @Option(name: .long, help: "App Store version ID")
    var versionId: String

    @Option(name: .long, help: "Build ID")
    var buildId: String

    func run() async throws {
        let repo = try ClientProvider.makeVersionRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any VersionRepository) async throws {
        try await repo.setBuild(versionId: versionId, buildId: buildId)
    }
}

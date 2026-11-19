import ArgumentParser
import ASCKit

struct ProfilesDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a provisioning profile"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Profile resource ID")
    var profileId: String

    func run() async throws {
        let repo = try ClientProvider.makeProfiles()
        try await execute(repo: repo)
    }

    func execute(repo: any Profiles) async throws {
        try await repo.deleteProfile(id: profileId)
    }
}

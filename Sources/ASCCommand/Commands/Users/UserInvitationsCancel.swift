import ArgumentParser
import Domain

struct UserInvitationsCancel: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cancel",
        abstract: "Cancel a pending user invitation"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "User invitation resource ID")
    var invitationId: String

    func run() async throws {
        let repo = try ClientProvider.makeUserRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any UserRepository) async throws {
        try await repo.cancelUserInvitation(id: invitationId)
    }
}

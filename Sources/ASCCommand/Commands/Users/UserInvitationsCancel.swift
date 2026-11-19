import ArgumentParser
import ASCKit

struct UserInvitationsCancel: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cancel",
        abstract: "Cancel a pending user invitation"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "User invitation resource ID")
    var invitationId: String

    func run() async throws {
        let repo = try ClientProvider.makeUsers()
        try await execute(repo: repo)
    }

    func execute(repo: any Users) async throws {
        try await repo.cancelUserInvitation(id: invitationId)
    }
}

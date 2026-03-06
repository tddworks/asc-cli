import ArgumentParser

struct UserInvitationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "user-invitations",
        abstract: "Manage pending App Store Connect user invitations",
        subcommands: [
            UserInvitationsList.self,
            UserInvitationsInvite.self,
            UserInvitationsCancel.self,
        ]
    )
}

import ArgumentParser

struct UsersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "users",
        abstract: "Manage App Store Connect team members",
        subcommands: [
            UsersList.self,
            UsersUpdate.self,
            UsersRemove.self,
        ]
    )
}

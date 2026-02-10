import ArgumentParser

struct BuildsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "builds",
        abstract: "Manage builds",
        subcommands: [BuildsList.self]
    )
}

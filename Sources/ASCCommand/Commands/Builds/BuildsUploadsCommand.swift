import ArgumentParser

struct BuildsUploadsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uploads",
        abstract: "Manage build upload records",
        subcommands: [BuildsUploadsList.self, BuildsUploadsGet.self, BuildsUploadsDelete.self]
    )
}

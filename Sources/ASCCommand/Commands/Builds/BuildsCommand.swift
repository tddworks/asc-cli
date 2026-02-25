import ArgumentParser

struct BuildsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "builds",
        abstract: "Manage builds",
        subcommands: [
            BuildsList.self,
            BuildsUpload.self,
            BuildsUploadsCommand.self,
            BuildsAddBetaGroup.self,
            BuildsRemoveBetaGroup.self,
            BuildsUpdateBetaNotes.self,
        ]
    )
}

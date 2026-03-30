import ArgumentParser

struct BuildsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "builds",
        abstract: "Manage builds",
        subcommands: [
            BuildsList.self,
            BuildsNextNumber.self,
            BuildsUpload.self,
            BuildsArchive.self,
            BuildsUploadsCommand.self,
            BuildsAddBetaGroup.self,
            BuildsRemoveBetaGroup.self,
            BuildsUpdateBetaNotes.self,
        ]
    )
}

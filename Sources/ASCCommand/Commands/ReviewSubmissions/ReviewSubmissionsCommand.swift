import ArgumentParser

struct ReviewSubmissionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "review-submissions",
        abstract: "Inspect App Store review submissions (state, rejected items, drill-in affordances)",
        subcommands: [
            ReviewSubmissionsList.self,
            ReviewSubmissionsGet.self,
            ReviewSubmissionItemsCommand.self,
        ]
    )
}

import ArgumentParser

struct ReviewSubmissionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "review-submissions",
        abstract: "List App Store review submissions",
        subcommands: [ReviewSubmissionsList.self]
    )
}

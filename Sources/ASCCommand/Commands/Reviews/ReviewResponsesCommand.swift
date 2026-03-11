import ArgumentParser

struct ReviewResponsesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "review-responses",
        abstract: "Manage customer review responses",
        subcommands: [ReviewResponsesGet.self, ReviewResponsesCreate.self, ReviewResponsesDelete.self]
    )
}

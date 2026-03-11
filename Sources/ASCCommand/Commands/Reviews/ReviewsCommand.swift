import ArgumentParser

struct ReviewsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reviews",
        abstract: "Manage customer reviews",
        subcommands: [ReviewsList.self, ReviewsGet.self]
    )
}

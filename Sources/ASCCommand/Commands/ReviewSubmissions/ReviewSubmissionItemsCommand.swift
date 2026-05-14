import ArgumentParser

struct ReviewSubmissionItemsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "items",
        abstract: "Inspect per-item review state inside a submission (find which item Apple rejected)",
        subcommands: [ReviewSubmissionItemsList.self]
    )
}

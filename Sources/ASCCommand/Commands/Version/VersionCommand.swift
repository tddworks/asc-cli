import ArgumentParser

struct VersionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Print the CLI version"
    )

    func run() {
        print("asc 0.1.0")
    }
}

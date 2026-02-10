import ArgumentParser

@main
struct ASC: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "asc",
        abstract: "App Store Connect CLI",
        version: "0.1.0",
        subcommands: [
            AppsCommand.self,
            BuildsCommand.self,
            TestFlightCommand.self,
            AuthCommand.self,
            VersionCommand.self,
        ]
    )
}

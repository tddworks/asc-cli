import ArgumentParser

struct IrisCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iris",
        abstract: "App Store Connect private API (cookie-based auth)",
        subcommands: [
            IrisStatus.self,
            IrisAppsCommand.self,
            IrisIAPSubmissionsCommand.self,
            IrisResolutionCenterCommand.self,
            IrisAuthCommand.self,
        ]
    )
}

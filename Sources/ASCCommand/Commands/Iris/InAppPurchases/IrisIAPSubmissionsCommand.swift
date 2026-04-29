import ArgumentParser

struct IrisIAPSubmissionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap-submissions",
        abstract: "Submit in-app purchases via the iris private API (supports submitWithNextAppStoreVersion)",
        subcommands: [IrisIAPSubmissionsCreate.self, IrisIAPSubmissionsDelete.self]
    )
}

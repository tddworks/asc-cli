import ArgumentParser

/// `asc iris resolution-center` — App Review's Resolution Center (rejection
/// messages and guideline citations), readable only via the iris private API.
struct IrisResolutionCenterCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "resolution-center",
        abstract: "Read App Review's Resolution Center messages for review submissions",
        subcommands: [IrisResolutionCenterGet.self]
    )
}

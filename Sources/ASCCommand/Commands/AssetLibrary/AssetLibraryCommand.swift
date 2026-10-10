import ArgumentParser
import Domain

extension AssetPlacementType: ExpressibleByArgument {}
extension LibraryAssetState: ExpressibleByArgument {}
extension AssetCategory: ExpressibleByArgument {}

struct AssetLibraryCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "asset-library",
        abstract: "Read an app's asset library — upload images and videos once, then place them",
        subcommands: [AssetLibraryGet.self]
    )
}

struct AssetLibraryGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get the app's asset library"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeAssetLibraryRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AssetLibraryRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let library = try await repo.getAssetLibrary(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([library], affordanceMode: affordanceMode)
    }
}

struct AssetPlacementGroupsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "asset-placement-groups",
        abstract: "List placement groups (device families) and their sizes and limits from App Store Connect's reference data",
        subcommands: [AssetPlacementGroupsList.self]
    )
}

struct AssetPlacementGroupsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List placement groups, one row per placement type and group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Placement type, e.g. APP_SCREENSHOT, APP_PREVIEW")
    var placementType: AssetPlacementType?

    @Option(name: .long, help: "App Store feature whose limits to show, e.g. APP_STORE_VERSIONS, CUSTOM_PRODUCT_PAGES")
    var feature: String?

    func run() async throws {
        let repo = try ClientProvider.makeAssetLibraryRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AssetLibraryRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let groups = try await repo.listPlacementGroups(placementType: placementType, feature: feature)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(groups, affordanceMode: affordanceMode)
    }
}

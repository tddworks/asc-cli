import ArgumentParser
import Domain
import Foundation

struct AppPreviewSetsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-preview-sets",
        abstract: "Manage App Store app preview sets",
        subcommands: [AppPreviewSetsList.self, AppPreviewSetsCreate.self]
    )
}

struct AppPreviewSetsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List app preview sets for an App Store version localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makePreviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PreviewRepository) async throws -> String {
        let sets = try await repo.listPreviewSets(localizationId: localizationId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            sets,
            headers: ["ID", "Preview Type", "Device", "Count"],
            rowMapper: { [$0.id, $0.previewType.rawValue, $0.deviceCategory.displayName, "\($0.previewsCount)"] }
        )
    }
}

struct AppPreviewSetsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create an app preview set for a localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version localization ID")
    var localizationId: String

    @Option(name: .long, help: "Preview type raw value (e.g. IPHONE_67, IPAD_PRO_3GEN_129, APPLE_TV)")
    var previewType: String

    func run() async throws {
        let repo = try ClientProvider.makePreviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PreviewRepository) async throws -> String {
        guard let type = PreviewType(rawValue: previewType) else {
            throw ValidationError("Invalid preview type '\(previewType)'. Use a raw value like IPHONE_67, IPAD_PRO_3GEN_129, APPLE_TV, APPLE_VISION_PRO.")
        }
        let set = try await repo.createPreviewSet(localizationId: localizationId, previewType: type)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [set],
            headers: ["ID", "Preview Type", "Device", "Count"],
            rowMapper: { [$0.id, $0.previewType.rawValue, $0.deviceCategory.displayName, "\($0.previewsCount)"] }
        )
    }
}

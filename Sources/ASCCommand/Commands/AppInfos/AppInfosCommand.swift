import ArgumentParser
import ASCKit

struct AppInfosCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-infos",
        abstract: "Manage App Store app info",
        subcommands: [AppInfosList.self, AppInfosUpdate.self]
    )
}

struct AppInfosList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List app infos for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppInfos()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppInfos) async throws -> String {
        let infos = try await repo.listAppInfos(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            infos,
            headers: ["ID", "App ID"],
            rowMapper: { [$0.id, $0.appId] }
        )
    }
}

struct AppInfosUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update app info categories"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App info ID")
    var appInfoId: String

    @Option(name: .long, help: "Primary category ID (e.g. 6014 for Games)")
    var primaryCategory: String?

    @Option(name: .long, help: "Primary subcategory 1 ID")
    var primarySubcategoryOne: String?

    @Option(name: .long, help: "Primary subcategory 2 ID")
    var primarySubcategoryTwo: String?

    @Option(name: .long, help: "Secondary category ID")
    var secondaryCategory: String?

    @Option(name: .long, help: "Secondary subcategory 1 ID")
    var secondarySubcategoryOne: String?

    @Option(name: .long, help: "Secondary subcategory 2 ID")
    var secondarySubcategoryTwo: String?

    func run() async throws {
        let repo = try ClientProvider.makeAppInfos()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppInfos) async throws -> String {
        let info = try await repo.updateCategories(
            id: appInfoId,
            primaryCategoryId: primaryCategory,
            primarySubcategoryOneId: primarySubcategoryOne,
            primarySubcategoryTwoId: primarySubcategoryTwo,
            secondaryCategoryId: secondaryCategory,
            secondarySubcategoryOneId: secondarySubcategoryOne,
            secondarySubcategoryTwoId: secondarySubcategoryTwo
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [info],
            headers: ["ID", "App ID", "Primary Category"],
            rowMapper: { [$0.id, $0.appId, $0.primaryCategoryId ?? "-"] }
        )
    }
}

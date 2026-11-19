import ArgumentParser
import ASCKit

struct BundleIDsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a bundle identifier"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Bundle ID resource ID")
    var bundleIdId: String

    func run() async throws {
        let repo = try ClientProvider.makeBundleIDRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any BundleIDRepository) async throws {
        try await repo.deleteBundleID(id: bundleIdId)
    }
}

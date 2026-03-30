import ArgumentParser
import Domain

struct BuildsUploadsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a build upload record"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build upload ID")
    var uploadId: String

    func run() async throws {
        let repo = try ClientProvider.makeBuildUploadRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any BuildUploadRepository) async throws {
        try await repo.deleteBuildUpload(id: uploadId)
    }
}

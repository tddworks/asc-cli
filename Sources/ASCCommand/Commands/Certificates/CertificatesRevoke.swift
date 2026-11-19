import ArgumentParser
import ASCKit

struct CertificatesRevoke: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "revoke",
        abstract: "Revoke a signing certificate"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Certificate resource ID")
    var certificateId: String

    func run() async throws {
        let repo = try ClientProvider.makeCertificateRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any CertificateRepository) async throws {
        try await repo.revokeCertificate(id: certificateId)
    }
}

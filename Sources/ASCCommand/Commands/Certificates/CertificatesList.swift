import ArgumentParser
import Domain

struct CertificatesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List signing certificates"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by certificate type (e.g. IOS_DISTRIBUTION, MAC_APP_STORE)")
    var type: String?

    func run() async throws {
        let repo = try ClientProvider.makeCertificateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any CertificateRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let certType = type.flatMap { CertificateType(rawValue: $0.uppercased()) }
        let items = try await repo.listCertificates(certificateType: certType)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}

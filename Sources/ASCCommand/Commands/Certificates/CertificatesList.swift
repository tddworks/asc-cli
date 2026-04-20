import ArgumentParser
import Domain
import Foundation

struct CertificatesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List signing certificates"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by certificate type (e.g. IOS_DISTRIBUTION, MAC_APP_STORE)")
    var type: String?

    @Option(name: .long, help: "Maximum number of certificates to return (server-side)")
    var limit: Int?

    @Flag(name: .long, help: "Only return certificates whose expirationDate has passed")
    var expiredOnly: Bool = false

    @Option(name: .long, help: "Only return certificates with expirationDate strictly before this ISO8601 date")
    var before: String?

    func run() async throws {
        let repo = try ClientProvider.makeCertificateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any CertificateRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let certType = type.flatMap { CertificateType(rawValue: $0.uppercased()) }
        var items = try await repo.listCertificates(certificateType: certType, limit: limit)

        if expiredOnly {
            items = items.filter(\.isExpired)
        }
        if let before {
            guard let cutoff = ISO8601DateFormatter().date(from: before) else {
                throw ValidationError("--before must be an ISO8601 date (e.g. 2025-11-14T22:13:20Z)")
            }
            items = items.filter { cert in
                guard let exp = cert.expirationDate else { return false }
                return exp < cutoff
            }
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}

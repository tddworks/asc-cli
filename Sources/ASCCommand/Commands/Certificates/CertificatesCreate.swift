import ArgumentParser
import ASCKit
import Foundation

struct CertificatesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a signing certificate from a CSR"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Certificate type (e.g. IOS_DISTRIBUTION, MAC_APP_DISTRIBUTION)")
    var type: String

    @Option(name: .long, help: "Path to the .csr file — use this for PEM files (avoids shell quoting issues with dashes)")
    var csrPath: String?

    @Option(name: .long, help: "CSR content as a string — NOTE: PEM files start with '-----' which breaks shell argument parsing; use --csr-path instead")
    var csrContent: String?

    func run() async throws {
        let repo = try ClientProvider.makeCertificates()
        print(try await execute(repo: repo))
    }

    func execute(repo: any Certificates) async throws -> String {
        guard let certType = CertificateType(rawValue: type.uppercased()) else {
            throw ValidationError("Invalid certificate type '\(type)'.")
        }
        let pem: String
        if let path = csrPath {
            pem = try String(contentsOfFile: path, encoding: .utf8)
        } else if let content = csrContent {
            pem = content
        } else {
            throw ValidationError("Provide either --csr-path <file> or --csr-content <pem>.")
        }
        let item = try await repo.createCertificate(certificateType: certType, csrContent: pem)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Name", "Type"],
            rowMapper: { [$0.id, $0.name, $0.certificateType.rawValue] }
        )
    }
}

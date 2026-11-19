import ArgumentParser
import ASCKit

struct BetaReviewDetailUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update beta app review contact details"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta app review detail ID")
    var detailId: String

    @Option(name: .long, help: "Contact first name")
    var contactFirstName: String?

    @Option(name: .long, help: "Contact last name")
    var contactLastName: String?

    @Option(name: .long, help: "Contact phone number")
    var contactPhone: String?

    @Option(name: .long, help: "Contact email address")
    var contactEmail: String?

    @Option(name: .long, help: "Demo account username")
    var demoAccountName: String?

    @Option(name: .long, help: "Demo account password")
    var demoAccountPassword: String?

    @Flag(name: .long, help: "Demo account is required")
    var demoAccountRequired: Bool = false

    @Option(name: .long, help: "Review notes")
    var notes: String?

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BetaAppReviewRepository) async throws -> String {
        let update = ASCKit.BetaAppReviewDetailUpdate(
            contactFirstName: contactFirstName,
            contactLastName: contactLastName,
            contactPhone: contactPhone,
            contactEmail: contactEmail,
            demoAccountName: demoAccountName,
            demoAccountPassword: demoAccountPassword,
            demoAccountRequired: demoAccountRequired ? true : nil,
            notes: notes
        )
        let detail = try await repo.updateDetail(id: detailId, update: update)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [detail],
            headers: ["ID", "Contact", "Demo Required", "Notes"],
            rowMapper: {
                let contact = [$0.contactFirstName, $0.contactLastName].compactMap { $0 }.joined(separator: " ")
                return [$0.id, contact.isEmpty ? "-" : contact, $0.demoAccountRequired ? "Yes" : "No", $0.notes ?? "-"]
            }
        )
    }
}

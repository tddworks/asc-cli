import ArgumentParser
import Domain

struct VersionReviewDetailCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version-review-detail",
        abstract: "Manage App Store version review information",
        subcommands: [VersionReviewDetailGet.self, VersionReviewDetailUpdate.self]
    )
}

// MARK: - Get

struct VersionReviewDetailGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get review contact info for an App Store version"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Version ID")
    var versionId: String

    func run() async throws {
        let repo = try ClientProvider.makeReviewDetailRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ReviewDetailRepository) async throws -> String {
        let detail = try await repo.getReviewDetail(versionId: versionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [detail],
            headers: ["ID", "Contact Email", "Contact Phone", "Demo Required"],
            rowMapper: { [
                $0.id,
                $0.contactEmail ?? "-",
                $0.contactPhone ?? "-",
                $0.demoAccountRequired ? "yes" : "no",
            ] }
        )
    }
}

// MARK: - Update

struct VersionReviewDetailUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Set or update review contact info for an App Store version (upserts)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Version ID")
    var versionId: String

    @Option(name: .long, help: "Reviewer's first name")
    var contactFirstName: String?

    @Option(name: .long, help: "Reviewer's last name")
    var contactLastName: String?

    @Option(name: .long, help: "Reviewer's phone number")
    var contactPhone: String?

    @Option(name: .long, help: "Reviewer's email address")
    var contactEmail: String?

    @Option(name: .long, help: "Demo account required (true/false)")
    var demoAccountRequired: Bool?

    @Option(name: .long, help: "Demo account username")
    var demoAccountName: String?

    @Option(name: .long, help: "Demo account password")
    var demoAccountPassword: String?

    @Option(name: .long, help: "Notes for the reviewer")
    var notes: String?

    func run() async throws {
        let repo = try ClientProvider.makeReviewDetailRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ReviewDetailRepository) async throws -> String {
        let update = ReviewDetailUpdate(
            contactFirstName: contactFirstName,
            contactLastName: contactLastName,
            contactPhone: contactPhone,
            contactEmail: contactEmail,
            demoAccountRequired: demoAccountRequired,
            demoAccountName: demoAccountName,
            demoAccountPassword: demoAccountPassword,
            notes: notes
        )
        let detail = try await repo.upsertReviewDetail(versionId: versionId, update: update)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [detail],
            headers: ["ID", "Contact Email", "Contact Phone", "Demo Required"],
            rowMapper: { [
                $0.id,
                $0.contactEmail ?? "-",
                $0.contactPhone ?? "-",
                $0.demoAccountRequired ? "yes" : "no",
            ] }
        )
    }
}

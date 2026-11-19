import ArgumentParser
import ASCKit

struct IrisAppComplianceDeclare: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "declare",
        abstract: "Answer an App Compliance requirement",
        discussion: "--answer no declares the app doesn't offer the regulated feature in the region (or it is disabled or geoblocked there)."
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Requirement ID, from `asc iris app-compliance list`")
    var requirementId: String

    @Option(name: .long, help: "yes or no")
    var answer: DeclaredAnswerArgument

    func run() async throws {
        print(try await execute(cookieProvider: ClientProvider.makeIrisCookieProvider(), repo: ClientProvider.makeIrisComplianceRepository()))
    }

    func execute(cookieProvider: any IrisCookieProvider, repo: any IrisComplianceRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let session = try cookieProvider.resolveSession()
        let requirement = try await repo.requirement(requirementId, appId: appId, session: session)
        let declared = try await requirement.declare(try answer.answer(), session: session, repo: repo)
        return try OutputFormatter(format: globals.outputFormat, pretty: globals.pretty).formatAgentItems([declared], affordanceMode: affordanceMode)
    }
}

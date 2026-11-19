import ArgumentParser
import Foundation
import ASCKit

struct IrisAppComplianceDeclare: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "declare",
        abstract: "Answer an App Compliance requirement",
        discussion: """
        --answer no declares the app doesn't offer the regulated feature in the region (or it is \
        disabled or geoblocked there). --answer yes sends the requirement's evidence:
          Security Assessment: --proof <file> --report <file>
          AI Generated or Synthetic Content: --filing-type llm|algorithm --filing-name <name> \
        --filing-number <number> [--third-party-authorization <file> when third-party technology powers it]
        Files are .doc, .docx, .jpeg, .jpg, .pdf or .png.
        """
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Requirement ID, from `asc iris app-compliance list`")
    var requirementId: String

    @Option(name: .long, help: "yes or no")
    var answer: DeclaredAnswerArgument

    @Option(name: .long, help: "Security Assessment: the proof of a completed assessment (file)")
    var proof: String?

    @Option(name: .long, help: "Security Assessment: the assessment report (file)")
    var report: String?

    @Option(name: .long, help: "AIGC: llm or algorithm")
    var filingType: AIGCFiling.FilingType?

    @Option(name: .long, help: "AIGC: the LLM or algorithm name, as filed")
    var filingName: String?

    @Option(name: .long, help: "AIGC: the filing number")
    var filingNumber: String?

    @Option(name: .long, help: "AIGC: the authorization or usage agreement for third-party technology (file)")
    var thirdPartyAuthorization: String?

    func run() async throws {
        print(try await execute(cookieProvider: ClientProvider.makeIrisCookieProvider(), repo: ClientProvider.makeIrisComplianceRepository()))
    }

    func execute(cookieProvider: any IrisCookieProvider, repo: any IrisComplianceRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let session = try cookieProvider.resolveSession()
        let requirement = try await repo.requirement(requirementId, appId: appId, session: session)
        let declared = try await requirement.declare(try answer.answer(for: requirement.kind, evidence: try evidence()), session: session, repo: repo)
        return try OutputFormatter(format: globals.outputFormat, pretty: globals.pretty).formatAgentItems([declared], affordanceMode: affordanceMode)
    }

    private func evidence() throws -> ComplianceEvidenceInput {
        func read(_ path: String?) throws -> ComplianceFile? {
            guard let path else { return nil }
            let url = URL(fileURLWithPath: path)
            return ComplianceFile(name: url.lastPathComponent, data: try Data(contentsOf: url))
        }
        return ComplianceEvidenceInput(
            proof: try read(proof), report: try read(report),
            filingType: filingType, filingName: filingName, filingNumber: filingNumber,
            thirdPartyAuthorization: try read(thirdPartyAuthorization)
        )
    }
}

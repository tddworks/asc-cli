import ArgumentParser
import ASCKit

/// `asc iris app-compliance` — the app's App Compliance page (China mainland Security
/// Assessment, AI generated content). Iris private API only: there is no public endpoint.
struct IrisAppComplianceCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-compliance",
        abstract: "List and answer an app's App Compliance requirements (iris session)",
        subcommands: [IrisAppComplianceList.self, IrisAppComplianceDeclare.self]
    )
}

/// The Yes or No a developer gives on the command line or in a REST body.
enum DeclaredAnswerArgument: String, ExpressibleByArgument, CaseIterable {
    case yes
    case no

    /// The answer to send. A Yes needs evidence (not yet supported), so only No is sent.
    func answer() throws -> ComplianceAnswer {
        switch self {
        case .no: return .notOffered
        case .yes: throw ValidationError("Answering yes needs evidence asc can't send yet. Answer yes on the App Compliance page.")
        }
    }
}

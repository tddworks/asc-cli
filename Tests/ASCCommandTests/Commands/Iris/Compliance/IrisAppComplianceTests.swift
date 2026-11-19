import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IrisAppComplianceTests {
    private func cookies() -> MockIrisCookieProvider {
        let provider = MockIrisCookieProvider()
        given(provider).resolveSession().willReturn(IrisSession(cookies: "myacinfo=a"))
        return provider
    }

    private let missing = ComplianceRequirement(
        id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
        status: .missingInfo, updatedAt: nil, requiredActions: [], declarationId: nil
    )
    private let pending = ComplianceRequirement(
        id: "req-2", appId: "1234567890", kind: .aiGeneratedContent, regions: ["CHN"], isRequired: true,
        status: .pendingVerification, updatedAt: "2026-11-17T00:00:00.000Z", requiredActions: [.appBinarySubmission],
        declarationId: "form-2"
    )
    private var declaredNo: ComplianceRequirement {
        ComplianceRequirement(id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
                              status: .active, updatedAt: "2026-11-19T00:00:00.000Z", requiredActions: [],
                              declarationId: "form-1")
    }

    private func repo() -> MockIrisComplianceRepository {
        let repo = MockIrisComplianceRepository()
        given(repo).listRequirements(session: .any, appId: .value("1234567890")).willReturn([missing, pending])
        given(repo).declare(session: .any, requirement: .value(missing), answer: .value(.notOffered)).willReturn(declaredNo)
        return repo
    }

    @Test func `should list every requirement on the app's App Compliance page with what to do next`() async throws {
        let cmd = try IrisAppComplianceList.parse(["--app-id", "1234567890", "--pretty"])

        let output = try await cmd.execute(cookieProvider: cookies(), repo: repo())

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "declare" : "asc iris app-compliance declare --answer <yes|no> --app-id 1234567890 --requirement-id req-1",
                "listRequirements" : "asc iris app-compliance list --app-id 1234567890"
              },
              "appId" : "1234567890",
              "id" : "req-1",
              "isRequired" : true,
              "kind" : "SECURITY_ASSESSMENT",
              "name" : "Security Assessment",
              "regions" : [
                "CHN"
              ],
              "requiredActions" : [

              ],
              "status" : "MISSING_INFO"
            },
            {
              "affordances" : {
                "listRequirements" : "asc iris app-compliance list --app-id 1234567890"
              },
              "appId" : "1234567890",
              "declarationId" : "form-2",
              "id" : "req-2",
              "isRequired" : true,
              "kind" : "AI_GENERATED_CONTENT",
              "name" : "AI Generated or Synthetic Content",
              "regions" : [
                "CHN"
              ],
              "requiredActions" : [
                "APP_BINARY_SUBMISSION"
              ],
              "status" : "PENDING_VERIFICATION",
              "updatedAt" : "2026-11-17T00:00:00.000Z"
            }
          ]
        }
        """)
    }

    @Test func `should declare No for a requirement and show it active`() async throws {
        let cmd = try IrisAppComplianceDeclare.parse(["--app-id", "1234567890", "--requirement-id", "req-1", "--answer", "no"])

        let output = try await cmd.execute(cookieProvider: cookies(), repo: repo())

        let json = try #require(try JSONSerialization.jsonObject(with: Data(output.utf8)) as? [String: Any])
        let row = try #require((json["data"] as? [[String: Any]])?.first)
        #expect(row["status"] as? String == "ACTIVE")
        #expect(row["declarationId"] as? String == "form-1")
    }

    @Test func `should refuse to declare while Apple is verifying the answer`() async throws {
        let cmd = try IrisAppComplianceDeclare.parse(["--app-id", "1234567890", "--requirement-id", "req-2", "--answer", "no"])

        await #expect(throws: ComplianceError.notDeclarable(kind: .aiGeneratedContent, status: .pendingVerification)) {
            try await cmd.execute(cookieProvider: cookies(), repo: repo())
        }
    }

    @Test func `should say which requirement the app doesn't have`() async throws {
        let cmd = try IrisAppComplianceDeclare.parse(["--app-id", "1234567890", "--requirement-id", "req-9", "--answer", "no"])

        await #expect(throws: ComplianceError.requirementNotFound(requirementId: "req-9", appId: "1234567890")) {
            try await cmd.execute(cookieProvider: cookies(), repo: repo())
        }
        #expect(ComplianceError.requirementNotFound(requirementId: "req-9", appId: "1234567890").description
            == "App 1234567890 has no compliance requirement req-9. See `asc iris app-compliance list --app-id 1234567890`.")
    }

    // MARK: - a Yes with evidence

    private func file(_ name: String, _ contents: String) throws -> String {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent(name)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: url)
        return url.path
    }

    @Test func `should declare a Security Assessment Yes with the proof and report read from disk`() async throws {
        let proof = try file("proof.pdf", "P"), report = try file("report.png", "R")
        let yes = ComplianceAnswer.offered(.securityAssessment(
            proof: ComplianceFile(name: "proof.pdf", data: Data("P".utf8)), report: ComplianceFile(name: "report.png", data: Data("R".utf8))
        ))
        let repo = repo()
        given(repo).declare(session: .any, requirement: .value(missing), answer: .value(yes)).willReturn(pending)
        let cmd = try IrisAppComplianceDeclare.parse([
            "--app-id", "1234567890", "--requirement-id", "req-1", "--answer", "yes", "--proof", proof, "--report", report,
        ])

        let output = try await cmd.execute(cookieProvider: cookies(), repo: repo)

        #expect(output.contains("\"status\":\"PENDING_VERIFICATION\""))
    }

    @Test func `should say what a Yes still needs before sending anything`() async throws {
        let cmd = try IrisAppComplianceDeclare.parse([
            "--app-id", "1234567890", "--requirement-id", "req-1", "--answer", "yes", "--proof", try file("proof.pdf", "P"),
        ])
        let repo = repo()

        await #expect(throws: ComplianceError.evidenceMissing(kind: .securityAssessment, missing: ["the Security Assessment Report"])) {
            try await cmd.execute(cookieProvider: cookies(), repo: repo)
        }
        verify(repo).declare(session: .any, requirement: .any, answer: .any).called(0)
    }

    @Test func `should declare an AIGC Yes from its filing and third-party agreement`() async throws {
        let aigc = ComplianceRequirement(id: "req-3", appId: "1234567890", kind: .aiGeneratedContent, regions: ["CHN"], isRequired: true,
                                         status: .missingInfo, updatedAt: nil, requiredActions: [], declarationId: nil)
        let yes = ComplianceAnswer.offered(.aiGeneratedContent(
            filing: .largeLanguageModel(name: "Example Model", filingNumber: "Example-0000"),
            thirdParty: .used(authorization: ComplianceFile(name: "agreement.pdf", data: Data("A".utf8)))
        ))
        let repo = MockIrisComplianceRepository()
        given(repo).listRequirements(session: .any, appId: .any).willReturn([aigc])
        given(repo).declare(session: .any, requirement: .value(aigc), answer: .value(yes)).willReturn(pending)
        let cmd = try IrisAppComplianceDeclare.parse([
            "--app-id", "1234567890", "--requirement-id", "req-3", "--answer", "yes",
            "--filing-type", "llm", "--filing-name", "Example Model", "--filing-number", "Example-0000",
            "--third-party-authorization", try file("agreement.pdf", "A"),
        ])

        _ = try await cmd.execute(cookieProvider: cookies(), repo: repo)

        verify(repo).declare(session: .any, requirement: .any, answer: .value(yes)).called(1)
    }

    @Test func `should accept only yes or no as the answer`() {
        #expect(throws: (any Error).self) {
            try IrisAppComplianceDeclare.parse(["--app-id", "1234567890", "--requirement-id", "req-1", "--answer", "maybe"])
        }
    }
}

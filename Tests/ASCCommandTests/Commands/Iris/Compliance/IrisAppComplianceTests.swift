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
        status: .missingInfo, updatedAt: nil, requiredActions: [], declaration: nil
    )
    private let pending = ComplianceRequirement(
        id: "req-2", appId: "1234567890", kind: .aiGeneratedContent, regions: ["CHN"], isRequired: true,
        status: .pendingVerification, updatedAt: "2026-11-17T00:00:00.000Z", requiredActions: [.appBinarySubmission],
        declaration: ComplianceDeclaration(id: "form-2", answer: .yes)
    )
    private var declaredNo: ComplianceRequirement {
        ComplianceRequirement(id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
                              status: .active, updatedAt: "2026-11-19T00:00:00.000Z", requiredActions: [],
                              declaration: ComplianceDeclaration(id: "form-1", answer: .no))
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
              "declaration" : {
                "answer" : "YES",
                "id" : "form-2"
              },
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
        #expect((row["declaration"] as? [String: Any])?["answer"] as? String == "NO")
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

    @Test func `should accept only yes or no as the answer`() {
        #expect(throws: (any Error).self) {
            try IrisAppComplianceDeclare.parse(["--app-id", "1234567890", "--requirement-id", "req-1", "--answer", "maybe"])
        }
    }
}

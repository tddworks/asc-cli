import Foundation
import Hummingbird
import HummingbirdTesting
import HummingbirdWebSocket
import Mockable
import NIOCore
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IrisAppComplianceRoutesTests {
    private let missing = ComplianceRequirement(
        id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
        status: .missingInfo, updatedAt: nil, requiredActions: [], declarationId: nil
    )
    private let declaredNo = ComplianceRequirement(
        id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
        status: .active, updatedAt: "2026-11-19T00:00:00.000Z", requiredActions: [],
        declarationId: "form-1"
    )

    private func call(_ method: HTTPRequest.Method, _ uri: String, body: String? = nil) async throws -> (HTTPResponse.Status, String) {
        let cookies = MockIrisCookieProvider()
        given(cookies).resolveSession().willReturn(IrisSession(cookies: "myacinfo=a"))
        let repo = MockIrisComplianceRepository()
        given(repo).listRequirements(session: .any, appId: .value("1234567890")).willReturn([missing])
        given(repo).declare(session: .any, requirement: .value(missing), answer: .value(.notOffered)).willReturn(declaredNo)
        given(repo).declare(session: .any, requirement: .value(missing), answer: .value(.offered(.securityAssessment(
            proof: ComplianceFile(name: "proof.pdf", data: Data("P".utf8)), report: ComplianceFile(name: "report.png", data: Data("R".utf8))
        )))).willReturn(declaredNo)
        let router = Router(context: BasicWebSocketRequestContext.self)
        IrisAppComplianceController(cookieProvider: cookies, repo: repo).addRoutes(to: router.group("/api/v1"))
        return try await Application(router: router).test(.router) { client in
            try await client.execute(uri: uri, method: method, body: body.map { ByteBuffer(string: $0) }) {
                ($0.status, String(buffer: $0.body))
            }
        }
    }

    @Test func `should list an app's compliance requirements over REST with their links`() async throws {
        let (status, body) = try await call(.get, "/api/v1/iris/apps/1234567890/compliance-requirements")

        #expect(status == .ok)
        let row = try #require(((try JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])?["data"] as? [[String: Any]])?.first)
        #expect(row["status"] as? String == "MISSING_INFO")
        let declare = (row["_links"] as? [String: Any])?["declare"] as? [String: String]
        #expect(declare == ["href": "/api/v1/iris/apps/1234567890/compliance-requirements/req-1/declare", "method": "POST"])
    }

    @Test func `should declare No over REST`() async throws {
        let (status, body) = try await call(.post, "/api/v1/iris/apps/1234567890/compliance-requirements/req-1/declare",
                                            body: #"{"answer":"no"}"#)

        #expect(status == .ok)
        let row = try #require(((try JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])?["data"] as? [[String: Any]])?.first)
        #expect(row["status"] as? String == "ACTIVE")
    }

    @Test func `should declare a Yes over REST with its files as base64`() async throws {
        let body = #"{"answer":"yes","evidence":{"proof":{"name":"proof.pdf","data":"UA=="},"report":{"name":"report.png","data":"Ug=="}}}"#

        let (status, _) = try await call(.post, "/api/v1/iris/apps/1234567890/compliance-requirements/req-1/declare", body: body)

        #expect(status == .ok)
    }

    @Test func `should say what a Yes over REST still needs`() async throws {
        let body = #"{"answer":"yes","evidence":{"proof":{"name":"proof.pdf","data":"UA=="}}}"#

        let (status, response) = try await call(.post, "/api/v1/iris/apps/1234567890/compliance-requirements/req-1/declare", body: body)

        #expect(status == .unprocessableContent)
        #expect(response.contains("A Yes to Security Assessment needs the Security Assessment Report."))
    }

    @Test func `should refuse an answer that isn't yes or no`() async throws {
        let (status, body) = try await call(.post, "/api/v1/iris/apps/1234567890/compliance-requirements/req-1/declare",
                                            body: #"{"answer":"maybe"}"#)

        #expect(status == .badRequest)
        #expect(body.contains("answer must be \\\"yes\\\" or \\\"no\\\""))
    }

    @Test func `should answer 404 for a requirement the app doesn't have`() async throws {
        let (status, body) = try await call(.post, "/api/v1/iris/apps/1234567890/compliance-requirements/req-9/declare",
                                            body: #"{"answer":"no"}"#)

        #expect(status == .notFound)
        #expect(body.contains("App 1234567890 has no compliance requirement req-9"))
    }
}

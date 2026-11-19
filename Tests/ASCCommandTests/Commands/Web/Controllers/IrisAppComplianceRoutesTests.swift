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
        status: .missingInfo, updatedAt: nil, requiredActions: [], declaration: nil
    )
    private let declaredNo = ComplianceRequirement(
        id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
        status: .active, updatedAt: "2026-11-19T00:00:00.000Z", requiredActions: [],
        declaration: ComplianceDeclaration(id: "form-1", answer: .no)
    )

    private func call(_ method: HTTPRequest.Method, _ uri: String, body: String? = nil) async throws -> (HTTPResponse.Status, String) {
        let cookies = MockIrisCookieProvider()
        given(cookies).resolveSession().willReturn(IrisSession(cookies: "myacinfo=a"))
        let repo = MockIrisComplianceRepository()
        given(repo).listRequirements(session: .any, appId: .value("1234567890")).willReturn([missing])
        given(repo).declare(session: .any, requirement: .value(missing), answer: .value(.notOffered)).willReturn(declaredNo)
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

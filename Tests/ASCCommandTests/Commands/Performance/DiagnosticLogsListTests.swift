import Testing
import Mockable
@testable import ASCKit
@testable import ASCCommand

@Suite
struct DiagnosticLogsListTests {

    @Test func `listed diagnostic logs show metadata and affordances`() async throws {
        let mockRepo = MockDiagnosticsRepository()
        given(mockRepo).listLogs(signatureId: .any).willReturn([
            DiagnosticLogEntry(
                id: "sig-1-0-0",
                signatureId: "sig-1",
                bundleId: "com.example.app",
                appVersion: "2.0",
                buildVersion: "100",
                osVersion: "iOS 17.0",
                deviceType: "iPhone15,2",
                event: "hang",
                callStackSummary: "main > UIKit > layoutSubviews"
            )
        ])
        let cmd = try DiagnosticLogsList.parse(["--signature-id", "sig-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLogs" : "asc diagnostic-logs list --signature-id sig-1"
              },
              "appVersion" : "2.0",
              "buildVersion" : "100",
              "bundleId" : "com.example.app",
              "callStackSummary" : "main > UIKit > layoutSubviews",
              "deviceType" : "iPhone15,2",
              "event" : "hang",
              "id" : "sig-1-0-0",
              "osVersion" : "iOS 17.0",
              "signatureId" : "sig-1"
            }
          ]
        }
        """)
    }
}

import Testing
import Mockable
@testable import Domain
@testable import ASCCommand

@Suite
struct DiagnosticsListTests {

    @Test func `diagnostic type filter is parsed from CLI argument`() async throws {
        let mockRepo = MockDiagnosticsRepository()
        given(mockRepo).listSignatures(buildId: .any, diagnosticType: .any).willReturn([])
        let cmd = try DiagnosticsList.parse(["--build-id", "build-1", "--diagnostic-type", "DISK_WRITES"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("\"data\""))
    }

    @Test func `listed diagnostic signatures show type, weight, and affordances`() async throws {
        let mockRepo = MockDiagnosticsRepository()
        given(mockRepo).listSignatures(buildId: .any, diagnosticType: .any).willReturn([
            DiagnosticSignatureInfo(
                id: "sig-1",
                buildId: "build-1",
                diagnosticType: .hangs,
                signature: "main thread hang in layoutSubviews",
                weight: 45.2,
                insightDirection: "UP"
            )
        ])
        let cmd = try DiagnosticsList.parse(["--build-id", "build-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLogs" : "asc diagnostic-logs list --signature-id sig-1",
                "listSignatures" : "asc diagnostics list --build-id build-1"
              },
              "buildId" : "build-1",
              "diagnosticType" : "HANGS",
              "id" : "sig-1",
              "insightDirection" : "UP",
              "signature" : "main thread hang in layoutSubviews",
              "weight" : 45.2
            }
          ]
        }
        """)
    }
}

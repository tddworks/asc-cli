import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BuildsSetEncryptionComplianceTests {

    @Test func `set-encryption-compliance returns the updated build with affordances`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).updateBuildEncryptionCompliance(buildId: .any, usesNonExemptEncryption: .any)
            .willReturn(Build(
                id: "b-1", version: "1.0", expired: false,
                processingState: .valid, buildNumber: "42",
                usesNonExemptEncryption: false
            ))

        let cmd = try BuildsSetEncryptionCompliance.parse([
            "--build-id", "b-1",
            "--uses-non-exempt-encryption", "false",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "addToTestFlight" : "asc builds add-beta-group --build-id b-1 --beta-group-id <beta-group-id>",
                "updateBetaNotes" : "asc builds update-beta-notes --build-id b-1 --locale en-US --notes <notes>"
              },
              "buildNumber" : "42",
              "expired" : false,
              "id" : "b-1",
              "processingState" : "VALID",
              "usesNonExemptEncryption" : false,
              "version" : "1.0"
            }
          ]
        }
        """)
    }

    @Test func `set-encryption-compliance accepts true to declare non-exempt encryption`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).updateBuildEncryptionCompliance(buildId: .any, usesNonExemptEncryption: .any)
            .willReturn(Build(
                id: "b-1", version: "1.0", buildNumber: "42",
                usesNonExemptEncryption: true
            ))

        let cmd = try BuildsSetEncryptionCompliance.parse([
            "--build-id", "b-1",
            "--uses-non-exempt-encryption", "true",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo)
            .updateBuildEncryptionCompliance(buildId: .value("b-1"), usesNonExemptEncryption: .value(true))
            .called(1)
    }
}

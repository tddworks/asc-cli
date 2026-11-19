import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BuildsUploadsGetTests {

    @Test func `execute returns upload with affordances`() async throws {
        let mockRepo = MockBuildUploadRepository()
        given(mockRepo).getBuildUpload(id: .any)
            .willReturn(BuildUpload(id: "up-1", appId: "app-1", version: "2.0", buildNumber: "55", platform: .iOS, state: .complete))

        let cmd = try BuildsUploadsGet.parse(["--upload-id", "up-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkStatus" : "asc builds uploads get --upload-id up-1",
                "listBuilds" : "asc builds list --app-id app-1"
              },
              "appId" : "app-1",
              "buildNumber" : "55",
              "id" : "up-1",
              "platform" : "IOS",
              "state" : "COMPLETE",
              "version" : "2.0"
            }
          ]
        }
        """)
    }

    @Test func `table output includes id version build and state`() async throws {
        let mockRepo = MockBuildUploadRepository()
        given(mockRepo).getBuildUpload(id: .any)
            .willReturn(BuildUpload(id: "up-1", appId: "app-1", version: "1.0", buildNumber: "10", platform: .macOS, state: .processing))

        let cmd = try BuildsUploadsGet.parse(["--upload-id", "up-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("up-1"))
        #expect(output.contains("1.0"))
        #expect(output.contains("PROCESSING"))
    }
}

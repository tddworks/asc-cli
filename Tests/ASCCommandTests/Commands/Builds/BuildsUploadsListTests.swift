import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BuildsUploadsListTests {

    @Test func `execute returns list of uploads`() async throws {
        let mockRepo = MockBuildUploadRepository()
        given(mockRepo).listBuildUploads(appId: .any).willReturn([
            BuildUpload(id: "up-1", appId: "app-1", version: "1.0", buildNumber: "1", platform: .iOS, state: .complete),
            BuildUpload(id: "up-2", appId: "app-1", version: "1.1", buildNumber: "2", platform: .iOS, state: .processing),
        ])

        let cmd = try BuildsUploadsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("up-1"))
        #expect(output.contains("up-2"))
        #expect(output.contains("COMPLETE"))
        #expect(output.contains("PROCESSING"))
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockBuildUploadRepository()
        given(mockRepo).listBuildUploads(appId: .any).willReturn([
            BuildUpload(id: "up-1", appId: "app-1", version: "2.0", buildNumber: "99", platform: .iOS, state: .failed),
        ])

        let cmd = try BuildsUploadsList.parse(["--app-id", "app-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("up-1"))
        #expect(output.contains("2.0"))
        #expect(output.contains("FAILED"))
    }
}

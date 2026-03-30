import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BuildsNextNumberTests {

    @Test func `next number is 4 when highest build is 3`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .value("app-1"), platform: .value(.iOS), version: .value("1.0.1"), limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "1.0.1", buildNumber: "3", platform: .iOS),
                Build(id: "b-2", version: "1.0.1", buildNumber: "2", platform: .iOS),
                Build(id: "b-3", version: "1.0.1", buildNumber: "1", platform: .iOS),
            ], nextCursor: nil)
        )

        let cmd = try BuildsNextNumber.parse(["--app-id", "app-1", "--version", "1.0.1", "--platform", "ios", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : {
            "affordances" : {
              "archiveAndUpload" : "asc builds archive --scheme <scheme> --platform ios --upload --app-id app-1 --version 1.0.1 --build-number 4",
              "uploadBuild" : "asc builds upload --app-id app-1 --file <path> --version 1.0.1 --build-number 4 --platform ios"
            },
            "appId" : "app-1",
            "nextBuildNumber" : 4,
            "platform" : "IOS",
            "version" : "1.0.1"
          }
        }
        """)
    }

    @Test func `next number is 1 when no builds exist`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .value("app-1"), platform: .value(.iOS), version: .value("2.0"), limit: .any).willReturn(
            PaginatedResponse(data: [], nextCursor: nil)
        )

        let cmd = try BuildsNextNumber.parse(["--app-id", "app-1", "--version", "2.0", "--platform", "ios", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : {
            "affordances" : {
              "archiveAndUpload" : "asc builds archive --scheme <scheme> --platform ios --upload --app-id app-1 --version 2.0 --build-number 1",
              "uploadBuild" : "asc builds upload --app-id app-1 --file <path> --version 2.0 --build-number 1 --platform ios"
            },
            "appId" : "app-1",
            "nextBuildNumber" : 1,
            "platform" : "IOS",
            "version" : "2.0"
          }
        }
        """)
    }

    @Test func `plain output shows just the number`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, platform: .any, version: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "1.0", buildNumber: "7"),
            ], nextCursor: nil)
        )

        let cmd = try BuildsNextNumber.parse(["--app-id", "app-1", "--version", "1.0", "--platform", "ios"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "8")
    }
}

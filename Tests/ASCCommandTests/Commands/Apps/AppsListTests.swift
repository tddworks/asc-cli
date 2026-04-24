import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppsListTests {

    @Test func `listed apps include name bundleId and affordances`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "app-1", name: "My App", bundleId: "com.example.app", sku: "SKU1"),
            ], nextCursor: nil)
        )

        let cmd = try AppsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createVersion" : "asc versions create --app-id app-1",
                "listAppInfos" : "asc app-infos list --app-id app-1",
                "listReviews" : "asc reviews list --app-id app-1",
                "listVersions" : "asc versions list --app-id app-1",
                "updateContentRights" : "asc apps update --app-id app-1"
              },
              "bundleId" : "com.example.app",
              "id" : "app-1",
              "name" : "My App",
              "sku" : "SKU1"
            }
          ]
        }
        """)
    }

    @Test func `sku is omitted from output when not set`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "app-1", name: "No SKU App", bundleId: "com.example"),
            ], nextCursor: nil)
        )

        let cmd = try AppsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createVersion" : "asc versions create --app-id app-1",
                "listAppInfos" : "asc app-infos list --app-id app-1",
                "listReviews" : "asc reviews list --app-id app-1",
                "listVersions" : "asc versions list --app-id app-1",
                "updateContentRights" : "asc apps update --app-id app-1"
              },
              "bundleId" : "com.example",
              "id" : "app-1",
              "name" : "No SKU App"
            }
          ]
        }
        """)
    }
}

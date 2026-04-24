import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppsUpdateTests {

    @Test func `updated content rights declaration returns app with declaration set`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).updateContentRights(appId: .any, declaration: .any).willReturn(
            App(id: "app-9", name: "Bakery", bundleId: "com.example.bakery", contentRightsDeclaration: .doesNotUseThirdPartyContent)
        )

        let cmd = try AppsUpdate.parse([
            "--app-id", "app-9",
            "--content-rights-declaration", "DOES_NOT_USE_THIRD_PARTY_CONTENT",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createVersion" : "asc versions create --app-id app-9",
                "listAppInfos" : "asc app-infos list --app-id app-9",
                "listReviews" : "asc reviews list --app-id app-9",
                "listVersions" : "asc versions list --app-id app-9",
                "updateContentRights" : "asc apps update --app-id app-9"
              },
              "bundleId" : "com.example.bakery",
              "contentRightsDeclaration" : "DOES_NOT_USE_THIRD_PARTY_CONTENT",
              "id" : "app-9",
              "name" : "Bakery"
            }
          ]
        }
        """)
    }

    @Test func `rejects unknown content rights declaration values`() throws {
        let cmd = try AppsUpdate.parse([
            "--app-id", "app-9",
            "--content-rights-declaration", "BOGUS",
        ])
        #expect(throws: (any Error).self) {
            _ = try cmd.validateDeclaration()
        }
    }
}

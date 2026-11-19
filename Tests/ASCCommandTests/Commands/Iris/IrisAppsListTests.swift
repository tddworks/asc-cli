import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IrisAppsListTests {

    @Test func `listed apps show id name bundleId and affordances`() async throws {
        let mockCookieProvider = MockIrisCookieProvider()
        given(mockCookieProvider).resolveSession().willReturn(
            IrisSession(cookies: "myacinfo=test")
        )

        let mockRepo = MockIrisAppBundles()
        given(mockRepo).listAppBundles(session: .any).willReturn([
            AppBundle(
                id: "app-1",
                name: "My App",
                bundleId: "com.example.app",
                sku: "SKU1",
                primaryLocale: "en-US",
                platforms: ["IOS"]
            ),
        ])

        let cmd = try IrisAppsList.parse(["--pretty"])
        let output = try await cmd.execute(cookieProvider: mockCookieProvider, repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listAppInfos" : "asc app-infos list --app-id app-1",
                "listVersions" : "asc versions list --app-id app-1"
              },
              "bundleId" : "com.example.app",
              "id" : "app-1",
              "name" : "My App",
              "platforms" : [
                "IOS"
              ],
              "primaryLocale" : "en-US",
              "sku" : "SKU1"
            }
          ]
        }
        """)
    }
}

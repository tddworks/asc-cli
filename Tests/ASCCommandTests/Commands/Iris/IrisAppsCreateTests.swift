import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IrisAppsCreateTests {

    @Test func `created app shows id name bundleId and affordances`() async throws {
        let mockCookieProvider = MockIrisCookieProvider()
        given(mockCookieProvider).resolveSession().willReturn(
            IrisSession(cookies: "myacinfo=test")
        )

        let mockRepo = MockIrisAppBundles()
        given(mockRepo).createApp(
            session: .any,
            name: .any,
            bundleId: .any,
            sku: .any,
            primaryLocale: .any,
            platforms: .any,
            versionString: .any
        ).willReturn(
            AppBundle(
                id: "app-1",
                name: "My New App",
                bundleId: "com.example.newapp",
                sku: "NEWSKU",
                primaryLocale: "en-US",
                platforms: ["IOS"]
            )
        )

        let cmd = try IrisAppsCreate.parse([
            "--name", "My New App",
            "--bundle-id", "com.example.newapp",
            "--sku", "NEWSKU",
            "--pretty",
        ])
        let output = try await cmd.execute(cookieProvider: mockCookieProvider, repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listAppInfos" : "asc app-infos list --app-id app-1",
                "listVersions" : "asc versions list --app-id app-1"
              },
              "bundleId" : "com.example.newapp",
              "id" : "app-1",
              "name" : "My New App",
              "platforms" : [
                "IOS"
              ],
              "primaryLocale" : "en-US",
              "sku" : "NEWSKU"
            }
          ]
        }
        """)
    }
}

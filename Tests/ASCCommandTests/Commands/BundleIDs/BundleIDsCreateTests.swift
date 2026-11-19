import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BundleIDsCreateTests {

    @Test func `execute creates bundle id and returns it`() async throws {
        let mockRepo = MockBundleIDRepository()
        given(mockRepo).createBundleID(name: .any, identifier: .any, platform: .any)
            .willReturn(BundleID(id: "bid-new", name: "My App", identifier: "com.example.app", platform: .iOS))

        let cmd = try BundleIDsCreate.parse(["--name", "My App", "--identifier", "com.example.app", "--platform", "ios", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc bundle-ids delete --bundle-id-id bid-new",
                "listProfiles" : "asc profiles list --bundle-id-id bid-new"
              },
              "id" : "bid-new",
              "identifier" : "com.example.app",
              "name" : "My App",
              "platform" : "IOS"
            }
          ]
        }
        """)
    }

    @Test func `execute throws for invalid platform`() async throws {
        let mockRepo = MockBundleIDRepository()
        let cmd = try BundleIDsCreate.parse(["--name", "My App", "--identifier", "com.example.app", "--platform", "unknown"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockBundleIDRepository()
        given(mockRepo).createBundleID(name: .any, identifier: .any, platform: .any)
            .willReturn(BundleID(id: "bid-1", name: "Test App", identifier: "com.test.app", platform: .macOS))

        let cmd = try BundleIDsCreate.parse(["--name", "Test App", "--identifier", "com.test.app", "--platform", "macos", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("bid-1"))
        #expect(output.contains("com.test.app"))
        #expect(output.contains("macOS"))
    }
}

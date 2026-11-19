import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BundleIDsListTests {

    @Test func `listed bundle ids include identifier platform and affordances`() async throws {
        let mockRepo = MockBundleIDs()
        given(mockRepo).listBundleIDs(platform: .any, identifier: .any).willReturn([
            BundleID(id: "bid-1", name: "My App", identifier: "com.example.app", platform: .iOS),
        ])

        let cmd = try BundleIDsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc bundle-ids delete --bundle-id-id bid-1",
                "listProfiles" : "asc profiles list --bundle-id-id bid-1"
              },
              "id" : "bid-1",
              "identifier" : "com.example.app",
              "name" : "My App",
              "platform" : "IOS"
            }
          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockBundleIDs()
        given(mockRepo).listBundleIDs(platform: .any, identifier: .any).willReturn([
            BundleID(id: "bid-1", name: "My App", identifier: "com.example.app", platform: .iOS),
        ])

        let cmd = try BundleIDsList.parse(["--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("bid-1"))
        #expect(output.contains("com.example.app"))
        #expect(output.contains("iOS"))
    }

    @Test func `seed id is omitted from output when not set`() async throws {
        let mockRepo = MockBundleIDs()
        given(mockRepo).listBundleIDs(platform: .any, identifier: .any).willReturn([
            BundleID(id: "bid-1", name: "My App", identifier: "com.example.app", platform: .macOS),
        ])

        let cmd = try BundleIDsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc bundle-ids delete --bundle-id-id bid-1",
                "listProfiles" : "asc profiles list --bundle-id-id bid-1"
              },
              "id" : "bid-1",
              "identifier" : "com.example.app",
              "name" : "My App",
              "platform" : "MAC_OS"
            }
          ]
        }
        """)
    }
}

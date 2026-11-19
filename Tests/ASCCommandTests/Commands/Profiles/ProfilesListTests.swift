import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct ProfilesListTests {

    @Test func `listed profiles include bundleIdId type state and affordances`() async throws {
        let mockRepo = MockProfiles()
        given(mockRepo).listProfiles(bundleIdId: .any, profileType: .any).willReturn([
            Profile(
                id: "prof-1",
                name: "My App Store Profile",
                profileType: .iosAppStore,
                profileState: .active,
                bundleIdId: "bid-1"
            ),
        ])

        let cmd = try ProfilesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc profiles delete --profile-id prof-1",
                "listProfiles" : "asc profiles list --bundle-id-id bid-1"
              },
              "bundleIdId" : "bid-1",
              "id" : "prof-1",
              "name" : "My App Store Profile",
              "profileState" : "ACTIVE",
              "profileType" : "IOS_APP_STORE"
            }
          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockProfiles()
        given(mockRepo).listProfiles(bundleIdId: .any, profileType: .any).willReturn([
            Profile(id: "prof-1", name: "My Profile", profileType: .iosAppStore, profileState: .active, bundleIdId: "bid-1"),
        ])

        let cmd = try ProfilesList.parse(["--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("prof-1"))
        #expect(output.contains("IOS_APP_STORE"))
        #expect(output.contains("ACTIVE"))
    }

    @Test func `invalid profile state renders in output`() async throws {
        let mockRepo = MockProfiles()
        given(mockRepo).listProfiles(bundleIdId: .any, profileType: .any).willReturn([
            Profile(
                id: "prof-2",
                name: "Expired Profile",
                profileType: .macAppStore,
                profileState: .invalid,
                bundleIdId: "bid-2"
            ),
        ])

        let cmd = try ProfilesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc profiles delete --profile-id prof-2",
                "listProfiles" : "asc profiles list --bundle-id-id bid-2"
              },
              "bundleIdId" : "bid-2",
              "id" : "prof-2",
              "name" : "Expired Profile",
              "profileState" : "INVALID",
              "profileType" : "MAC_APP_STORE"
            }
          ]
        }
        """)
    }
}

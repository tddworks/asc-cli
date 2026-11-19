import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct ProfilesCreateTests {

    @Test func `execute creates profile and returns it`() async throws {
        let mockRepo = MockProfileRepository()
        given(mockRepo).createProfile(name: .any, profileType: .any, bundleIdId: .any, certificateIds: .any, deviceIds: .any)
            .willReturn(Profile(id: "prof-new", name: "My Profile", profileType: .iosAppStore, profileState: .active, bundleIdId: "bid-1"))

        let cmd = try ProfilesCreate.parse([
            "--name", "My Profile",
            "--type", "IOS_APP_STORE",
            "--bundle-id-id", "bid-1",
            "--certificate-ids", "cert-1,cert-2",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc profiles delete --profile-id prof-new",
                "listProfiles" : "asc profiles list --bundle-id-id bid-1"
              },
              "bundleIdId" : "bid-1",
              "id" : "prof-new",
              "name" : "My Profile",
              "profileState" : "ACTIVE",
              "profileType" : "IOS_APP_STORE"
            }
          ]
        }
        """)
    }

    @Test func `execute throws for invalid profile type`() async throws {
        let mockRepo = MockProfileRepository()
        let cmd = try ProfilesCreate.parse([
            "--name", "My Profile",
            "--type", "INVALID_TYPE",
            "--bundle-id-id", "bid-1",
            "--certificate-ids", "cert-1",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockProfileRepository()
        given(mockRepo).createProfile(name: .any, profileType: .any, bundleIdId: .any, certificateIds: .any, deviceIds: .any)
            .willReturn(Profile(id: "prof-1", name: "Mac Store", profileType: .macAppStore, profileState: .active, bundleIdId: "bid-2"))

        let cmd = try ProfilesCreate.parse([
            "--name", "Mac Store",
            "--type", "MAC_APP_STORE",
            "--bundle-id-id", "bid-2",
            "--certificate-ids", "cert-1",
            "--output", "table",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("prof-1"))
        #expect(output.contains("MAC_APP_STORE"))
        #expect(output.contains("ACTIVE"))
    }
}

import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppClipsListTests {

    @Test func `listed app clips include appId bundleId and affordances`() async throws {
        let mockRepo = MockAppClips()
        given(mockRepo).listAppClips(appId: .any).willReturn([
            AppClip(id: "clip-1", appId: "app-1", bundleId: "com.example.clip")
        ])

        let cmd = try AppClipsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listAppClips" : "asc app-clips list --app-id app-1",
                "listExperiences" : "asc app-clip-experiences list --app-clip-id clip-1"
              },
              "appId" : "app-1",
              "bundleId" : "com.example.clip",
              "id" : "clip-1"
            }
          ]
        }
        """)
    }

    @Test func `listed app clips omit nil bundleId from JSON`() async throws {
        let mockRepo = MockAppClips()
        given(mockRepo).listAppClips(appId: .any).willReturn([
            AppClip(id: "clip-1", appId: "app-1", bundleId: nil)
        ])

        let cmd = try AppClipsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listAppClips" : "asc app-clips list --app-id app-1",
                "listExperiences" : "asc app-clip-experiences list --app-clip-id clip-1"
              },
              "appId" : "app-1",
              "id" : "clip-1"
            }
          ]
        }
        """)
    }

    @Test func `table output includes clip id appId and bundleId`() async throws {
        let mockRepo = MockAppClips()
        given(mockRepo).listAppClips(appId: .any).willReturn([
            AppClip(id: "clip-1", appId: "app-1", bundleId: "com.example.clip")
        ])

        let cmd = try AppClipsList.parse(["--app-id", "app-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("clip-1"))
        #expect(output.contains("app-1"))
        #expect(output.contains("com.example.clip"))
    }
}

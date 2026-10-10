import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AssetLibraryCommandTests {

    @Test func `should show the app's asset library with where to go next`() async throws {
        let mockRepo = MockAssetLibraryRepository()
        given(mockRepo).getAssetLibrary(appId: .value("app-1")).willReturn(AppAssetLibrary(id: "lib-1", appId: "app-1"))

        let cmd = try AssetLibraryGet.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listImages" : "asc asset-images list --library-id lib-1",
                "listPlacementGroups" : "asc asset-placement-groups list --placement-type APP_SCREENSHOT",
                "listVideos" : "asc asset-videos list --library-id lib-1",
                "uploadImage" : "asc asset-images upload --file <file> --library-id lib-1"
              },
              "appId" : "app-1",
              "id" : "lib-1"
            }
          ]
        }
        """)
    }

    @Test func `should list placement groups of the requested type and feature with how to place into them`() async throws {
        let mockRepo = MockAssetLibraryRepository()
        given(mockRepo).listPlacementGroups(placementType: .value(.appScreenshot), feature: .value("APP_STORE_VERSIONS")).willReturn([
            AssetPlacementGroup(id: "IPHONE_DUO_PROFILE", placementType: .appScreenshot, platform: "IPHONE_APP_STORE",
                                displayClass: "IPHONE_DUO", feature: "APP_STORE_VERSIONS", sizes: ["1290x2796"], maxCount: 10),
        ])

        let cmd = try AssetPlacementGroupsList.parse(["--placement-type", "APP_SCREENSHOT", "--feature", "APP_STORE_VERSIONS", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "place" : "asc asset-placements create --image-id <image-id> --localization-id <localization-id> --placement-group IPHONE_DUO_PROFILE --placement-type APP_SCREENSHOT"
              },
              "displayClass" : "IPHONE_DUO",
              "feature" : "APP_STORE_VERSIONS",
              "id" : "IPHONE_DUO_PROFILE",
              "maxCount" : 10,
              "placementType" : "APP_SCREENSHOT",
              "platform" : "IPHONE_APP_STORE",
              "sizes" : [
                "1290x2796"
              ]
            }
          ]
        }
        """)
    }

    @Test func `should refuse a placement type App Store Connect doesn't have`() {
        #expect(throws: (any Error).self) {
            try AssetPlacementGroupsList.parse(["--placement-type", "HOLOGRAM"])
        }
    }
}

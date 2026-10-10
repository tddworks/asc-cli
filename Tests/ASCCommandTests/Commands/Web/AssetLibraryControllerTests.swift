import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AssetLibraryControllerTests {

    @Test func `should place the image sent over REST on the localization`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).createPlacement(
            surface: .value(.appStoreVersionLocalization), localizationId: .value("loc-1"), mediaType: .value(.image),
            assetId: .value("img-1"), placementType: .value(.appScreenshot), placementGroup: .value("IPHONE_67")
        ).willReturn(Self.placement(id: "pl-1"))

        let placement = try await AssetLibraryController.createPlacement(
            surface: .appStoreVersionLocalization, localizationId: "loc-1",
            json: ["imageId": "img-1", "placementType": "APP_SCREENSHOT", "placementGroup": "IPHONE_67"],
            repo: mockRepo
        )

        #expect(placement == Self.placement(id: "pl-1"))
    }

    @Test func `should refuse a REST placement that names no asset or an unknown placement type`() async throws {
        let mockRepo = MockAssetPlacementRepository()

        await #expect(throws: AssetLibraryController.BadRequest("Provide imageId, placementType and placementGroup")) {
            _ = try await AssetLibraryController.createPlacement(
                surface: .appStoreVersionLocalization, localizationId: "loc-1",
                json: ["placementType": "HOLOGRAM", "placementGroup": "IPHONE_67"], repo: mockRepo
            )
        }
    }

    @Test func `should reorder the group in the order sent over REST`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).reorderPlacements(
            surface: .value(.appStoreVersionLocalization), localizationId: .value("loc-1"),
            placementGroup: .value("IPHONE_67"), placementIds: .value(["pl-2", "pl-1"])
        ).willReturn([Self.placement(id: "pl-2"), Self.placement(id: "pl-1")])

        let placements = try await AssetLibraryController.reorderPlacements(
            surface: .appStoreVersionLocalization, localizationId: "loc-1",
            json: ["placementGroup": "IPHONE_67", "placementIds": ["pl-2", "pl-1"]], repo: mockRepo
        )

        #expect(placements.map(\.id) == ["pl-2", "pl-1"])
    }

    @Test func `should refuse a REST reorder without a group or placements`() async throws {
        let mockRepo = MockAssetPlacementRepository()

        await #expect(throws: AssetLibraryController.BadRequest("Provide placementGroup and placementIds")) {
            _ = try await AssetLibraryController.reorderPlacements(
                surface: .appStoreVersionLocalization, localizationId: "loc-1", json: ["placementIds": []], repo: mockRepo
            )
        }
    }

    static func placement(id: String) -> AssetPlacement {
        AssetPlacement(id: id, surface: .appStoreVersionLocalization, localizationId: "loc-1", mediaType: .image,
                       assetId: "img-1", placementType: .appScreenshot, placementGroup: "IPHONE_67", state: .assetProcessing)
    }
}

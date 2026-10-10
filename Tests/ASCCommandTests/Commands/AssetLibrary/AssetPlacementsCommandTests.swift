import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AssetPlacementsCommandTests {

    // MARK: - list

    @Test func `should list a localization's placements in display order with what can be done next`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).listPlacements(
            surface: .value(.appStoreVersionLocalization), localizationId: .value("loc-1"),
            placementType: .value(.appScreenshot), placementGroup: .value("IPHONE_67")
        ).willReturn([
            AssetPlacement(id: "pl-1", surface: .appStoreVersionLocalization, localizationId: "loc-1", mediaType: .image,
                           assetId: "img-1", placementType: .appScreenshot, placementGroup: "IPHONE_67", position: 1,
                           state: .parentPrepareForSubmission),
        ])

        let cmd = try AssetPlacementsList.parse([
            "--localization-id", "loc-1", "--placement-type", "APP_SCREENSHOT", "--placement-group", "IPHONE_67", "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc asset-placements delete --placement-id pl-1",
                "listAssetPlacements" : "asc asset-placements list --image-id img-1",
                "listPlacements" : "asc asset-placements list --localization-id loc-1",
                "reorderGroup" : "asc asset-placements reorder --localization-id loc-1 --placement-group IPHONE_67 --placement-ids <placement-ids>"
              },
              "assetId" : "img-1",
              "id" : "pl-1",
              "localizationId" : "loc-1",
              "mediaType" : "IMAGE",
              "placementGroup" : "IPHONE_67",
              "placementType" : "APP_SCREENSHOT",
              "position" : 1,
              "state" : "PARENT_PREPARE_FOR_SUBMISSION",
              "surface" : "APP_STORE_VERSION_LOCALIZATION"
            }
          ]
        }
        """)
    }

    @Test func `should list everywhere an image is placed`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).listAssetPlacements(mediaType: .value(.image), assetId: .value("img-1")).willReturn([
            AssetPlacement(id: "pl-1", surface: .appStoreVersionLocalization, localizationId: "loc-1", mediaType: .image,
                           assetId: "img-1", placementType: .appScreenshot, placementGroup: "IPHONE_67", state: .parentApproved),
        ])

        let cmd = try AssetPlacementsList.parse(["--image-id", "img-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"listAssetPlacements":"asc asset-placements list --image-id img-1","listPlacements":"asc asset-placements list --localization-id loc-1"},"assetId":"img-1","id":"pl-1","localizationId":"loc-1","mediaType":"IMAGE","placementGroup":"IPHONE_67","placementType":"APP_SCREENSHOT","state":"PARENT_APPROVED","surface":"APP_STORE_VERSION_LOCALIZATION"}]}"#)
    }

    @Test func `should ask for exactly one localization or image to list placements of`() {
        #expect(throws: (any Error).self) { try AssetPlacementsList.parse([]) }
        #expect(throws: (any Error).self) { try AssetPlacementsList.parse(["--localization-id", "loc-1", "--image-id", "img-1"]) }
        #expect(throws: (any Error).self) { try AssetPlacementsList.parse(["--image-id", "img-1", "--placement-group", "IPHONE_67"]) }
    }

    // MARK: - create

    @Test func `should place the image on the localization and show the new placement`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).createPlacement(
            surface: .value(.appStoreVersionLocalization), localizationId: .value("loc-1"), mediaType: .value(.image),
            assetId: .value("img-1"), placementType: .value(.appScreenshot), placementGroup: .value("IPHONE_67")
        ).willReturn(
            AssetPlacement(id: "pl-9", surface: .appStoreVersionLocalization, localizationId: "loc-1", mediaType: .image,
                           assetId: "img-1", placementType: .appScreenshot, placementGroup: "IPHONE_67", state: .assetProcessing)
        )

        let cmd = try AssetPlacementsCreate.parse([
            "--localization-id", "loc-1", "--image-id", "img-1", "--placement-type", "APP_SCREENSHOT", "--placement-group", "IPHONE_67",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"delete":"asc asset-placements delete --placement-id pl-9","listAssetPlacements":"asc asset-placements list --image-id img-1","listPlacements":"asc asset-placements list --localization-id loc-1","reorderGroup":"asc asset-placements reorder --localization-id loc-1 --placement-group IPHONE_67 --placement-ids <placement-ids>"},"assetId":"img-1","id":"pl-9","localizationId":"loc-1","mediaType":"IMAGE","placementGroup":"IPHONE_67","placementType":"APP_SCREENSHOT","state":"ASSET_PROCESSING","surface":"APP_STORE_VERSION_LOCALIZATION"}]}"#)
    }

    // MARK: - reorder

    @Test func `should show the group in the order it was given`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).reorderPlacements(
            surface: .value(.appStoreVersionLocalization), localizationId: .value("loc-1"),
            placementGroup: .value("IPHONE_67"), placementIds: .value(["pl-2", "pl-1"])
        ).willReturn([
            AssetPlacement(id: "pl-2", surface: .appStoreVersionLocalization, localizationId: "loc-1", mediaType: .image,
                           assetId: "img-2", placementType: .appScreenshot, placementGroup: "IPHONE_67", position: 1, state: .parentPrepareForSubmission),
            AssetPlacement(id: "pl-1", surface: .appStoreVersionLocalization, localizationId: "loc-1", mediaType: .image,
                           assetId: "img-1", placementType: .appScreenshot, placementGroup: "IPHONE_67", position: 2, state: .parentPrepareForSubmission),
        ])

        let cmd = try AssetPlacementsReorder.parse([
            "--localization-id", "loc-1", "--placement-group", "IPHONE_67", "--placement-ids", "pl-2, pl-1",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"delete":"asc asset-placements delete --placement-id pl-2","listAssetPlacements":"asc asset-placements list --image-id img-2","listPlacements":"asc asset-placements list --localization-id loc-1","reorderGroup":"asc asset-placements reorder --localization-id loc-1 --placement-group IPHONE_67 --placement-ids <placement-ids>"},"assetId":"img-2","id":"pl-2","localizationId":"loc-1","mediaType":"IMAGE","placementGroup":"IPHONE_67","placementType":"APP_SCREENSHOT","position":1,"state":"PARENT_PREPARE_FOR_SUBMISSION","surface":"APP_STORE_VERSION_LOCALIZATION"},{"affordances":{"delete":"asc asset-placements delete --placement-id pl-1","listAssetPlacements":"asc asset-placements list --image-id img-1","listPlacements":"asc asset-placements list --localization-id loc-1","reorderGroup":"asc asset-placements reorder --localization-id loc-1 --placement-group IPHONE_67 --placement-ids <placement-ids>"},"assetId":"img-1","id":"pl-1","localizationId":"loc-1","mediaType":"IMAGE","placementGroup":"IPHONE_67","placementType":"APP_SCREENSHOT","position":2,"state":"PARENT_PREPARE_FOR_SUBMISSION","surface":"APP_STORE_VERSION_LOCALIZATION"}]}"#)
    }

    // MARK: - delete

    @Test func `should report App Store Connect's refusal to delete a placement once the version is in review`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).deletePlacement(placementId: .value("pl-1")).willThrow(APIError.unknown("STATE_ERROR.INVALID_STATE"))

        let cmd = try AssetPlacementsDelete.parse(["--placement-id", "pl-1"])

        await #expect(throws: APIError.unknown("STATE_ERROR.INVALID_STATE")) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}

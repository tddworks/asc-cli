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
        #expect(throws: (any Error).self) { try AssetPlacementsList.parse(["--localization-id", "loc-1", "--treatment-localization-id", "tl-1"]) }
        #expect(throws: (any Error).self) { try AssetPlacementsList.parse(["--image-id", "img-1", "--placement-group", "IPHONE_67"]) }
    }

    @Test func `should list a treatment localization's placements`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).listPlacements(
            surface: .value(.experimentTreatmentLocalization), localizationId: .value("tl-1"), placementType: .value(nil), placementGroup: .value(nil)
        ).willReturn([
            AssetPlacement(id: "pl-1", surface: .experimentTreatmentLocalization, localizationId: "tl-1", mediaType: .image,
                           assetId: "img-1", placementType: .appScreenshot, placementGroup: "IPHONE_67", position: 1, state: .parentApproved),
        ])

        let cmd = try AssetPlacementsList.parse(["--treatment-localization-id", "tl-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"listAssetPlacements":"asc asset-placements list --image-id img-1","listPlacements":"asc asset-placements list --treatment-localization-id tl-1"},"assetId":"img-1","id":"pl-1","localizationId":"tl-1","mediaType":"IMAGE","placementGroup":"IPHONE_67","placementType":"APP_SCREENSHOT","position":1,"state":"PARENT_APPROVED","surface":"EXPERIMENT_TREATMENT_LOCALIZATION"}]}"#)
    }

    @Test func `should list everywhere a video is placed`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).listAssetPlacements(mediaType: .value(.video), assetId: .value("vid-1")).willReturn([
            AssetPlacement(id: "pl-1", surface: .appStoreVersionLocalization, localizationId: "loc-1", mediaType: .video,
                           assetId: "vid-1", placementType: .appPreview, placementGroup: "IPHONE_67", state: .parentApproved),
        ])

        let cmd = try AssetPlacementsList.parse(["--video-id", "vid-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"listAssetPlacements":"asc asset-placements list --video-id vid-1","listPlacements":"asc asset-placements list --localization-id loc-1"},"assetId":"vid-1","id":"pl-1","localizationId":"loc-1","mediaType":"VIDEO","placementGroup":"IPHONE_67","placementType":"APP_PREVIEW","state":"PARENT_APPROVED","surface":"APP_STORE_VERSION_LOCALIZATION"}]}"#)
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

    @Test func `should place a video on a treatment localization`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).createPlacement(
            surface: .value(.experimentTreatmentLocalization), localizationId: .value("tl-1"), mediaType: .value(.video),
            assetId: .value("vid-1"), placementType: .value(.appPreview), placementGroup: .value("IPHONE_67")
        ).willReturn(
            AssetPlacement(id: "pl-9", surface: .experimentTreatmentLocalization, localizationId: "tl-1", mediaType: .video,
                           assetId: "vid-1", placementType: .appPreview, placementGroup: "IPHONE_67", state: .assetProcessing)
        )

        let cmd = try AssetPlacementsCreate.parse([
            "--treatment-localization-id", "tl-1", "--video-id", "vid-1", "--placement-type", "APP_PREVIEW", "--placement-group", "IPHONE_67",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"delete":"asc asset-placements delete --placement-id pl-9","listAssetPlacements":"asc asset-placements list --video-id vid-1","listPlacements":"asc asset-placements list --treatment-localization-id tl-1","reorderGroup":"asc asset-placements reorder --placement-group IPHONE_67 --placement-ids <placement-ids> --treatment-localization-id tl-1"},"assetId":"vid-1","id":"pl-9","localizationId":"tl-1","mediaType":"VIDEO","placementGroup":"IPHONE_67","placementType":"APP_PREVIEW","state":"ASSET_PROCESSING","surface":"EXPERIMENT_TREATMENT_LOCALIZATION"}]}"#)
    }

    @Test func `should place a header image on a custom product page localization`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).createPlacement(
            surface: .value(.customProductPageLocalization), localizationId: .value("cpl-1"), mediaType: .value(.image),
            assetId: .value("img-1"), placementType: .value(.productPageHeaderAsset), placementGroup: .value("DEFAULT_PROFILE")
        ).willReturn(
            AssetPlacement(id: "pl-9", surface: .customProductPageLocalization, localizationId: "cpl-1", mediaType: .image,
                           assetId: "img-1", placementType: .productPageHeaderAsset, placementGroup: "DEFAULT_PROFILE", state: .assetProcessing)
        )

        let cmd = try AssetPlacementsCreate.parse([
            "--custom-product-page-localization-id", "cpl-1", "--image-id", "img-1",
            "--placement-type", "PRODUCT_PAGE_HEADER_ASSET", "--placement-group", "DEFAULT_PROFILE",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"delete":"asc asset-placements delete --placement-id pl-9","listAssetPlacements":"asc asset-placements list --image-id img-1","listPlacements":"asc asset-placements list --custom-product-page-localization-id cpl-1","reorderGroup":"asc asset-placements reorder --custom-product-page-localization-id cpl-1 --placement-group DEFAULT_PROFILE --placement-ids <placement-ids>"},"assetId":"img-1","id":"pl-9","localizationId":"cpl-1","mediaType":"IMAGE","placementGroup":"DEFAULT_PROFILE","placementType":"PRODUCT_PAGE_HEADER_ASSET","state":"ASSET_PROCESSING","surface":"CUSTOM_PRODUCT_PAGE_LOCALIZATION"}]}"#)
    }

    @Test func `should list a custom product page localization's placements`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).listPlacements(
            surface: .value(.customProductPageLocalization), localizationId: .value("cpl-1"),
            placementType: .value(.appStoreSearchResultsAsset), placementGroup: .value(nil)
        ).willReturn([
            AssetPlacement(id: "pl-1", surface: .customProductPageLocalization, localizationId: "cpl-1", mediaType: .image,
                           assetId: "img-1", placementType: .appStoreSearchResultsAsset, placementGroup: "DEFAULT_PROFILE", position: 1, state: .parentApproved),
        ])

        let cmd = try AssetPlacementsList.parse([
            "--custom-product-page-localization-id", "cpl-1", "--placement-type", "APP_STORE_SEARCH_RESULTS_ASSET",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"listAssetPlacements":"asc asset-placements list --image-id img-1","listPlacements":"asc asset-placements list --custom-product-page-localization-id cpl-1"},"assetId":"img-1","id":"pl-1","localizationId":"cpl-1","mediaType":"IMAGE","placementGroup":"DEFAULT_PROFILE","placementType":"APP_STORE_SEARCH_RESULTS_ASSET","position":1,"state":"PARENT_APPROVED","surface":"CUSTOM_PRODUCT_PAGE_LOCALIZATION"}]}"#)
    }

    @Test func `should refuse a custom product page localization together with another localization`() {
        #expect(throws: (any Error).self) {
            try AssetPlacementsCreate.parse(["--custom-product-page-localization-id", "cpl-1", "--localization-id", "loc-1",
                                             "--image-id", "img-1", "--placement-type", "PRODUCT_PAGE_HEADER_ASSET", "--placement-group", "DEFAULT_PROFILE"])
        }
        #expect(throws: (any Error).self) {
            try AssetPlacementsList.parse(["--custom-product-page-localization-id", "cpl-1", "--image-id", "img-1"])
        }
        #expect(throws: (any Error).self) {
            try AssetPlacementsReorder.parse(["--custom-product-page-localization-id", "cpl-1", "--treatment-localization-id", "tl-1",
                                              "--placement-group", "DEFAULT_PROFILE", "--placement-ids", "pl-1"])
        }
    }

    @Test func `should ask for exactly one localization and one asset to place`() {
        #expect(throws: (any Error).self) {
            try AssetPlacementsCreate.parse(["--localization-id", "loc-1", "--placement-type", "APP_SCREENSHOT", "--placement-group", "G"])
        }
        #expect(throws: (any Error).self) {
            try AssetPlacementsCreate.parse(["--image-id", "img-1", "--video-id", "vid-1", "--localization-id", "loc-1",
                                             "--placement-type", "APP_SCREENSHOT", "--placement-group", "G"])
        }
        #expect(throws: (any Error).self) {
            try AssetPlacementsCreate.parse(["--image-id", "img-1", "--placement-type", "APP_SCREENSHOT", "--placement-group", "G"])
        }
    }

    // MARK: - reorder

    @Test func `should reorder a group on a treatment localization`() async throws {
        let mockRepo = MockAssetPlacementRepository()
        given(mockRepo).reorderPlacements(
            surface: .value(.experimentTreatmentLocalization), localizationId: .value("tl-1"),
            placementGroup: .value("IPHONE_67"), placementIds: .value(["pl-1"])
        ).willReturn([
            AssetPlacement(id: "pl-1", surface: .experimentTreatmentLocalization, localizationId: "tl-1", mediaType: .image,
                           assetId: "img-1", placementType: .appScreenshot, placementGroup: "IPHONE_67", position: 1, state: .parentApproved),
        ])

        let cmd = try AssetPlacementsReorder.parse(["--treatment-localization-id", "tl-1", "--placement-group", "IPHONE_67", "--placement-ids", "pl-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"listAssetPlacements":"asc asset-placements list --image-id img-1","listPlacements":"asc asset-placements list --treatment-localization-id tl-1"},"assetId":"img-1","id":"pl-1","localizationId":"tl-1","mediaType":"IMAGE","placementGroup":"IPHONE_67","placementType":"APP_SCREENSHOT","position":1,"state":"PARENT_APPROVED","surface":"EXPERIMENT_TREATMENT_LOCALIZATION"}]}"#)
    }


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

import Foundation
import Testing
@testable import Domain

@Suite
struct AssetPlacementTests {

    // MARK: - States and surfaces

    @Test func `should use App Store Connect's own placement state names`() {
        #expect(PlacementState.allCases.map(\.rawValue) == [
            "ASSET_PROCESSING", "FAILED", "PARENT_PREPARE_FOR_SUBMISSION", "PARENT_READY_FOR_REVIEW",
            "PARENT_WAITING_FOR_REVIEW", "PARENT_IN_REVIEW", "PARENT_APPROVED",
            // Sent live by App Store Connect, though its spec omits it.
            "ACTIVE",
        ])
    }

    @Test func `should be editable while the asset processes, the parent is being prepared or the placement failed`() {
        #expect(PlacementState.allCases.filter(\.isEditable) == [.assetProcessing, .failed, .parentPrepareForSubmission])
    }

    @Test func `should not offer delete or reorder for an active placement whose meaning Apple doesn't document`() {
        let placement = MockRepositoryFactory.makeAssetPlacement(id: "pl-1", state: .active)
        #expect(placement.state.rawValue == "ACTIVE")
        #expect(placement.state.isEditable == false)
        #expect(placement.state.isInReview == false)
        #expect(placement.state.isLive == false)
        #expect(placement.affordances["delete"] == nil)
        #expect(placement.affordances["reorderGroup"] == nil)
    }

    @Test func `should be processing only while its asset is processed`() {
        #expect(PlacementState.allCases.filter(\.isProcessing) == [.assetProcessing])
    }

    @Test func `should be in review while the parent is submitted or in App Review`() {
        #expect(PlacementState.allCases.filter(\.isInReview) == [.parentReadyForReview, .parentWaitingForReview, .parentInReview])
    }

    @Test func `should be live once the parent is approved`() {
        #expect(PlacementState.allCases.filter(\.isLive) == [.parentApproved])
    }

    @Test func `should name every surface a placement can sit on the way App Store Connect does`() {
        #expect(PlacementSurface.allCases.map(\.rawValue) == [
            "APP_STORE_VERSION_LOCALIZATION", "EXPERIMENT_TREATMENT_LOCALIZATION",
            "CUSTOM_PRODUCT_PAGE_LOCALIZATION", "EVENT_LOCALIZATION",
        ])
    }

    @Test func `should allow ordering on every surface except in-app events`() {
        #expect(PlacementSurface.allCases.filter(\.isOrderable) == [
            .appStoreVersionLocalization, .experimentTreatmentLocalization, .customProductPageLocalization,
        ])
    }

    @Test func `should know every placement type App Store Connect offers`() {
        #expect(AssetPlacementType.allCases.map(\.rawValue) == [
            "APP_SCREENSHOT", "IMESSAGE_APP_SCREENSHOT", "APP_PREVIEW", "PRODUCT_PAGE_HEADER_ASSET",
            "APP_STORE_SEARCH_RESULTS_ASSET", "SEARCH_RESULTS_ADS_ASSET", "TODAY_TAB_ADS_ASSET",
            "EVENT_CARD_ASSET", "EVENT_DETAILS_PAGE_ASSET", "RETENTION_MESSAGE_ASSET",
        ])
    }

    // MARK: - Schema

    @Test func `should tie the placement to its localization and asset and leave out position when unknown`() throws {
        let placement = MockRepositoryFactory.makeAssetPlacement(
            id: "pl-1", surface: .appStoreVersionLocalization, localizationId: "loc-9", mediaType: .image,
            assetId: "img-1", placementType: .appScreenshot, placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
            position: nil, state: .parentPrepareForSubmission
        )

        #expect(try Self.json(placement) == #"{"assetId":"img-1","id":"pl-1","localizationId":"loc-9","mediaType":"IMAGE","placementGroup":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","placementType":"APP_SCREENSHOT","state":"PARENT_PREPARE_FOR_SUBMISSION","surface":"APP_STORE_VERSION_LOCALIZATION"}"#)
    }

    @Test func `should show its position in the group and why it failed`() throws {
        let placement = MockRepositoryFactory.makeAssetPlacement(
            id: "pl-1", localizationId: "loc-9", position: 2, state: .failed,
            stateDetails: [AssetStateDetail(code: "ASSET_FAILED", description: nil)]
        )

        #expect(try Self.json(placement) == #"{"assetId":"img-1","id":"pl-1","localizationId":"loc-9","mediaType":"IMAGE","placementGroup":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","placementType":"APP_SCREENSHOT","position":2,"state":"FAILED","stateDetails":[{"code":"ASSET_FAILED"}],"surface":"APP_STORE_VERSION_LOCALIZATION"}"#)
    }

    // MARK: - Affordances

    @Test func `should offer delete and reordering the group while the version is editable`() {
        let placement = MockRepositoryFactory.makeAssetPlacement(
            id: "pl-1", localizationId: "loc-1", assetId: "img-1",
            placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", state: .parentPrepareForSubmission
        )

        #expect(placement.affordances == [
            "delete": "asc asset-placements delete --placement-id pl-1",
            "listAssetPlacements": "asc asset-placements list --image-id img-1",
            "listPlacements": "asc asset-placements list --localization-id loc-1",
            "reorderGroup": "asc asset-placements reorder --localization-id loc-1 --placement-group IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE --placement-ids <placement-ids>",
        ])
    }

    @Test func `should offer neither delete nor reordering once the version is in review`() {
        let placement = MockRepositoryFactory.makeAssetPlacement(id: "pl-1", state: .parentInReview)

        #expect(placement.affordances["delete"] == nil)
        #expect(placement.affordances["reorderGroup"] == nil)
    }

    @Test func `should never offer reordering for an in-app event placement`() {
        let placement = MockRepositoryFactory.makeAssetPlacement(id: "pl-1", surface: .eventLocalization, state: .parentPrepareForSubmission)

        #expect(placement.affordances["reorderGroup"] == nil)
        #expect(placement.affordances["delete"] == "asc asset-placements delete --placement-id pl-1")
    }

    @Test func `should not point to sibling placements on a surface asc cannot list`() {
        let placement = MockRepositoryFactory.makeAssetPlacement(id: "pl-1", surface: .customProductPageLocalization)

        #expect(placement.affordances["listPlacements"] == nil)
        #expect(placement.affordances["reorderGroup"] == nil)
    }

    @Test func `should point to placements, deletion and reordering over REST`() {
        let placement = MockRepositoryFactory.makeAssetPlacement(id: "pl-1", localizationId: "loc-1", assetId: "img-1")

        #expect(placement.apiLinks["listPlacements"] == APILink(href: "/api/v1/version-localizations/loc-1/placements", method: "GET"))
        #expect(placement.apiLinks["listAssetPlacements"] == APILink(href: "/api/v1/asset-images/img-1/placements", method: "GET"))
        #expect(placement.apiLinks["delete"] == APILink(href: "/api/v1/asset-placements/pl-1", method: "DELETE"))
        #expect(placement.apiLinks["reorderGroup"] == APILink(href: "/api/v1/version-localizations/loc-1/placements/reorder", method: "POST"))
    }

    @Test func `should point to a treatment localization's placements and reorder them there`() {
        let placement = MockRepositoryFactory.makeAssetPlacement(
            id: "pl-1", surface: .experimentTreatmentLocalization, localizationId: "tl-1",
            placementGroup: "IPHONE_67", state: .parentPrepareForSubmission
        )

        #expect(placement.affordances["listPlacements"] == "asc asset-placements list --treatment-localization-id tl-1")
        #expect(placement.affordances["reorderGroup"] == "asc asset-placements reorder --placement-group IPHONE_67 --placement-ids <placement-ids> --treatment-localization-id tl-1")
        #expect(placement.apiLinks["listPlacements"] == APILink(href: "/api/v1/experiment-treatment-localizations/tl-1/placements", method: "GET"))
        #expect(placement.apiLinks["reorderGroup"] == APILink(href: "/api/v1/experiment-treatment-localizations/tl-1/placements/reorder", method: "POST"))
    }

    @Test func `should point a video placement to everywhere the video is placed`() {
        let placement = MockRepositoryFactory.makeAssetPlacement(id: "pl-1", mediaType: .video, assetId: "vid-1", placementType: .appPreview)

        #expect(placement.affordances["listAssetPlacements"] == "asc asset-placements list --video-id vid-1")
        #expect(placement.apiLinks["listAssetPlacements"] == APILink(href: "/api/v1/asset-videos/vid-1/placements", method: "GET"))
    }

    // MARK: - Table

    @Test func `should show type, group, position and state in a table`() {
        let placement = MockRepositoryFactory.makeAssetPlacement(id: "pl-1", assetId: "img-1", position: 1, state: .parentApproved)

        #expect(AssetPlacement.tableHeaders == ["ID", "Asset ID", "Type", "Group", "Position", "State"])
        #expect(placement.tableRow == ["pl-1", "img-1", "APP_SCREENSHOT", "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", "1", "PARENT_APPROVED"])
    }

    static func json(_ value: some Encodable) throws -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(data: try encoder.encode(value), encoding: .utf8)
    }
}

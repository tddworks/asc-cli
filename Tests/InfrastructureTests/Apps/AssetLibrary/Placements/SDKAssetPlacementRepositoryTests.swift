@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation
import Testing
@testable import Infrastructure

@Suite
struct SDKAssetPlacementRepositoryTests {

    // MARK: - listPlacements

    @Test func `should show a localization's placements with the media type App Store Connect sends in attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.placements("""
        {"data":[
          {"type":"appAssetLibraryPlacements","id":"pl-1",
           "attributes":{"mediaType":"IMAGE","placementType":"APP_SCREENSHOT","placementGroup":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","state":"PARENT_PREPARE_FOR_SUBMISSION","stateDetails":null},
           "relationships":{"image":{"data":{"type":"appAssetLibraryImages","id":"img-1"}},"video":{"links":{"self":""}}}},
          {"type":"appAssetLibraryPlacements","id":"pl-2",
           "attributes":{"mediaType":"VIDEO","placementType":"APP_PREVIEW","placementGroup":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","state":"ASSET_PROCESSING"},
           "relationships":{"video":{"data":{"type":"appAssetLibraryVideos","id":"vid-1"}}}}
        ],"links":{"self":""}}
        """))

        let placements = try await SDKAssetPlacementRepository(client: stub).listPlacements(
            surface: .appStoreVersionLocalization, localizationId: "loc-9", placementType: nil, placementGroup: nil
        )

        #expect(placements == [
            AssetPlacement(id: "pl-1", surface: .appStoreVersionLocalization, localizationId: "loc-9", mediaType: .image,
                           assetId: "img-1", placementType: .appScreenshot, placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
                           position: 1, state: .parentPrepareForSubmission),
            AssetPlacement(id: "pl-2", surface: .appStoreVersionLocalization, localizationId: "loc-9", mediaType: .video,
                           assetId: "vid-1", placementType: .appPreview, placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
                           position: 1, state: .assetProcessing),
        ])
    }

    @Test func `should number placements by their display order within each group`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.placements("""
        {"data":[
          \(Self.screenshot(id: "pl-1", group: "IPHONE_67", image: "img-1")),
          \(Self.screenshot(id: "pl-2", group: "IPAD_13", image: "img-2")),
          \(Self.screenshot(id: "pl-3", group: "IPHONE_67", image: "img-3"))
        ],"links":{"self":""}}
        """))

        let placements = try await SDKAssetPlacementRepository(client: stub).listPlacements(
            surface: .appStoreVersionLocalization, localizationId: "loc-9", placementType: nil, placementGroup: nil
        )

        #expect(placements.map { "\($0.id) \($0.placementGroup) \($0.position ?? 0)" } == [
            "pl-1 IPHONE_67 1", "pl-2 IPAD_13 1", "pl-3 IPHONE_67 2",
        ])
    }

    @Test func `should ask App Store Connect for the localization's placements in display order with their assets`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.placements(#"{"data":[],"links":{"self":""}}"#))

        _ = try await SDKAssetPlacementRepository(client: stub).listPlacements(
            surface: .appStoreVersionLocalization, localizationId: "loc-9",
            placementType: .appScreenshot, placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"
        )

        #expect(stub.lastPath == "/v1/appStoreVersionLocalizations/loc-9/placements")
        #expect(stub.lastQuery?.map { "\($0.0)=\($0.1 ?? "")" } == [
            "filter[placementType]=APP_SCREENSHOT", "filter[placementGroup]=IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
            "sort=placementGroupPosition", "limit=200", "include=image,video",
        ])
    }

    @Test func `should skip a placement of a type asc does not know yet instead of failing the list`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.placements("""
        {"data":[
          {"type":"appAssetLibraryPlacements","id":"pl-1",
           "attributes":{"mediaType":"IMAGE","placementType":"HOLOGRAM_ASSET","placementGroup":"HOLO","state":"PARENT_APPROVED"},
           "relationships":{"image":{"data":{"type":"appAssetLibraryImages","id":"img-1"}}}}
        ],"links":{"self":""}}
        """))

        let placements = try await SDKAssetPlacementRepository(client: stub).listPlacements(
            surface: .appStoreVersionLocalization, localizationId: "loc-9", placementType: nil, placementGroup: nil
        )

        #expect(placements == [])
    }

    @Test func `should read a treatment localization's placements from its own endpoint`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.placements(#"{"data":[\#(Self.screenshot(id: "pl-1", group: "IPHONE_67", image: "img-1"))],"links":{"self":""}}"#))

        let placements = try await SDKAssetPlacementRepository(client: stub).listPlacements(
            surface: .experimentTreatmentLocalization, localizationId: "tl-1", placementType: nil, placementGroup: nil
        )

        #expect(stub.lastPath == "/v1/appStoreVersionExperimentTreatmentLocalizations/tl-1/placements")
        #expect(placements.map { "\($0.surface.rawValue) \($0.localizationId)" } == ["EXPERIMENT_TREATMENT_LOCALIZATION tl-1"])
    }

    // MARK: - listAssetPlacements

    @Test func `should read everywhere a video is placed from the video's endpoint`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.placements("""
        {"data":[{"type":"appAssetLibraryPlacements","id":"pl-1",
          "attributes":{"mediaType":"VIDEO","placementType":"APP_PREVIEW","placementGroup":"IPHONE_67","state":"PARENT_APPROVED"},
          "relationships":{"appStoreVersionExperimentTreatmentLocalization":{"data":{"type":"appStoreVersionExperimentTreatmentLocalizations","id":"tl-1"}}}}
        ],"links":{"self":""}}
        """))

        let placements = try await SDKAssetPlacementRepository(client: stub).listAssetPlacements(mediaType: .video, assetId: "vid-1")

        #expect(stub.lastPath == "/v1/appAssetLibraryVideos/vid-1/placements")
        #expect(placements == [
            AssetPlacement(id: "pl-1", surface: .experimentTreatmentLocalization, localizationId: "tl-1", mediaType: .video,
                           assetId: "vid-1", placementType: .appPreview, placementGroup: "IPHONE_67", state: .parentApproved),
        ])
    }


    @Test func `should show which localization each placement of an image sits on`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.placements("""
        {"data":[
          {"type":"appAssetLibraryPlacements","id":"pl-1",
           "attributes":{"mediaType":"IMAGE","placementType":"APP_SCREENSHOT","placementGroup":"IPHONE_67","state":"PARENT_APPROVED"},
           "relationships":{"appStoreVersionLocalization":{"data":{"type":"appStoreVersionLocalizations","id":"loc-1"}}}},
          {"type":"appAssetLibraryPlacements","id":"pl-2",
           "attributes":{"mediaType":"IMAGE","placementType":"EVENT_CARD_ASSET","placementGroup":"EVENT_CARD","state":"PARENT_PREPARE_FOR_SUBMISSION"},
           "relationships":{"appEventLocalization":{"data":{"type":"appEventLocalizations","id":"evloc-1"}}}}
        ],"links":{"self":""}}
        """))

        let placements = try await SDKAssetPlacementRepository(client: stub).listAssetPlacements(mediaType: .image, assetId: "img-7")

        #expect(placements == [
            AssetPlacement(id: "pl-1", surface: .appStoreVersionLocalization, localizationId: "loc-1", mediaType: .image,
                           assetId: "img-7", placementType: .appScreenshot, placementGroup: "IPHONE_67", state: .parentApproved),
            AssetPlacement(id: "pl-2", surface: .eventLocalization, localizationId: "evloc-1", mediaType: .image,
                           assetId: "img-7", placementType: .eventCardAsset, placementGroup: "EVENT_CARD", state: .parentPrepareForSubmission),
        ])
        #expect(stub.lastPath == "/v1/appAssetLibraryImages/img-7/placements")
        #expect(stub.lastQuery?.map { "\($0.0)=\($0.1 ?? "")" } == [
            "limit=200",
            "include=appEventLocalization,appStoreVersionLocalization,appCustomProductPageLocalization,appStoreVersionExperimentTreatmentLocalization",
        ])
    }

    // MARK: - createPlacement

    @Test func `should send App Store Connect a placement naming the image and the version localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.placement("""
        {"data":{"type":"appAssetLibraryPlacements","id":"pl-1",
          "attributes":{"mediaType":"IMAGE","placementType":"APP_SCREENSHOT","placementGroup":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","state":"PARENT_PREPARE_FOR_SUBMISSION"}},
         "links":{"self":""}}
        """))

        let placement = try await SDKAssetPlacementRepository(client: stub).createPlacement(
            surface: .appStoreVersionLocalization, localizationId: "loc-9", mediaType: .image, assetId: "img-1",
            placementType: .appScreenshot, placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"
        )

        #expect(placement == AssetPlacement(
            id: "pl-1", surface: .appStoreVersionLocalization, localizationId: "loc-9", mediaType: .image, assetId: "img-1",
            placementType: .appScreenshot, placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", state: .parentPrepareForSubmission
        ))
        #expect(stub.requests.map { "\($0.method) \($0.path) \($0.body ?? "")" } == [
            #"POST /v1/appAssetLibraryPlacements {"data":{"attributes":{"placementGroup":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","placementType":"APP_SCREENSHOT"},"relationships":{"appStoreVersionLocalization":{"data":{"id":"loc-9","type":"appStoreVersionLocalizations"}},"image":{"data":{"id":"img-1","type":"appAssetLibraryImages"}}},"type":"appAssetLibraryPlacements"}}"#,
        ])
    }

    @Test func `should send App Store Connect a placement naming the video and the treatment localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.placement("""
        {"data":{"type":"appAssetLibraryPlacements","id":"pl-1",
          "attributes":{"mediaType":"VIDEO","placementType":"APP_PREVIEW","placementGroup":"IPHONE_67","state":"ASSET_PROCESSING"}},
         "links":{"self":""}}
        """))

        _ = try await SDKAssetPlacementRepository(client: stub).createPlacement(
            surface: .experimentTreatmentLocalization, localizationId: "tl-1", mediaType: .video, assetId: "vid-1",
            placementType: .appPreview, placementGroup: "IPHONE_67"
        )

        #expect(stub.requests.first?.body == #"{"data":{"attributes":{"placementGroup":"IPHONE_67","placementType":"APP_PREVIEW"},"relationships":{"appStoreVersionExperimentTreatmentLocalization":{"data":{"id":"tl-1","type":"appStoreVersionExperimentTreatmentLocalizations"}},"video":{"data":{"id":"vid-1","type":"appAssetLibraryVideos"}}},"type":"appAssetLibraryPlacements"}}"#)
    }

    // MARK: - reorderPlacements

    @Test func `should send the group's placements in the requested order and show the group in its new order`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.orderingResponse(#"{"data":{"type":"appAssetLibraryPlacementOrderingRequests","id":"ord-1"},"links":{"self":""}}"#))
        stub.willReturn(try Self.placements("""
        {"data":[
          \(Self.screenshot(id: "pl-2", group: "IPHONE_67", image: "img-2")),
          \(Self.screenshot(id: "pl-1", group: "IPHONE_67", image: "img-1"))
        ],"links":{"self":""}}
        """))

        let placements = try await SDKAssetPlacementRepository(client: stub).reorderPlacements(
            surface: .appStoreVersionLocalization, localizationId: "loc-9", placementGroup: "IPHONE_67", placementIds: ["pl-2", "pl-1"]
        )

        #expect(placements.map { "\($0.id) \($0.position ?? 0)" } == ["pl-2 1", "pl-1 2"])
        #expect(stub.requests.first.map { "\($0.method) \($0.path) \($0.body ?? "")" } ==
            #"POST /v1/appAssetLibraryPlacementOrderingRequests {"data":{"attributes":{"placementGroup":"IPHONE_67"},"relationships":{"appStoreVersionLocalization":{"data":{"id":"loc-9","type":"appStoreVersionLocalizations"}},"orderedPlacements":{"data":[{"id":"pl-2","type":"appAssetLibraryPlacements"},{"id":"pl-1","type":"appAssetLibraryPlacements"}]}},"type":"appAssetLibraryPlacementOrderingRequests"}}"#
        )
    }

    // MARK: - deletePlacement

    @Test func `should delete the placement`() async throws {
        let stub = StubAPIClient()

        try await SDKAssetPlacementRepository(client: stub).deletePlacement(placementId: "pl-1")

        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["DELETE /v1/appAssetLibraryPlacements/pl-1"])
    }

    // MARK: - Fixtures

    static func screenshot(id: String, group: String, image: String) -> String {
        """
        {"type":"appAssetLibraryPlacements","id":"\(id)",
         "attributes":{"mediaType":"IMAGE","placementType":"APP_SCREENSHOT","placementGroup":"\(group)","state":"PARENT_PREPARE_FOR_SUBMISSION"},
         "relationships":{"image":{"data":{"type":"appAssetLibraryImages","id":"\(image)"}}}}
        """
    }

    static func placements(_ json: String) throws -> AssetPlacementsDocument {
        try JSONDecoder().decode(AssetPlacementsDocument.self, from: Data(json.utf8))
    }

    static func placement(_ json: String) throws -> AssetPlacementDocument {
        try JSONDecoder().decode(AssetPlacementDocument.self, from: Data(json.utf8))
    }

    static func orderingResponse(_ json: String) throws -> PlacementOrderingDocument {
        try JSONDecoder().decode(PlacementOrderingDocument.self, from: Data(json.utf8))
    }
}

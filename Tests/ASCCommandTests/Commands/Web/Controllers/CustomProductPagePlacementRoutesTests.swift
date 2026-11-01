import Hummingbird
import HummingbirdTesting
import HummingbirdWebSocket
import Mockable
import NIOCore
import Testing
@testable import ASCCommand
@testable import Domain
@testable import Infrastructure

@Suite
struct CustomProductPagePlacementRoutesTests {

    @Test func `should place a header image on a custom product page localization over REST`() async throws {
        let placementRepo = MockAssetPlacementRepository()
        given(placementRepo).createPlacement(
            surface: .value(.customProductPageLocalization), localizationId: .value("cpl-1"), mediaType: .value(.image),
            assetId: .value("img-1"), placementType: .value(.productPageHeaderAsset), placementGroup: .value("DEFAULT_PROFILE")
        ).willReturn(
            AssetPlacement(id: "pl-9", surface: .customProductPageLocalization, localizationId: "cpl-1", mediaType: .image,
                           assetId: "img-1", placementType: .productPageHeaderAsset, placementGroup: "DEFAULT_PROFILE", state: .assetProcessing)
        )

        let (status, body) = try await Self.send(
            .post, "/api/v1/custom-product-page-localizations/cpl-1/placements",
            body: #"{"imageId":"img-1","placementType":"PRODUCT_PAGE_HEADER_ASSET","placementGroup":"DEFAULT_PROFILE"}"#,
            placementRepo: placementRepo
        )

        #expect(status == .ok)
        #expect(body.contains(#""id":"pl-9""#))
        #expect(body.contains(#""surface":"CUSTOM_PRODUCT_PAGE_LOCALIZATION""#))
        #expect(body.contains(#"/api/v1/custom-product-page-localizations/cpl-1/placements"#))
    }

    @Test func `should list a custom product page localization's placements over REST`() async throws {
        let placementRepo = MockAssetPlacementRepository()
        given(placementRepo).listPlacements(
            surface: .value(.customProductPageLocalization), localizationId: .value("cpl-1"),
            placementType: .value(.appStoreSearchResultsAsset), placementGroup: .value(nil)
        ).willReturn([
            AssetPlacement(id: "pl-1", surface: .customProductPageLocalization, localizationId: "cpl-1", mediaType: .image,
                           assetId: "img-1", placementType: .appStoreSearchResultsAsset, placementGroup: "DEFAULT_PROFILE", state: .parentApproved),
        ])

        let (status, body) = try await Self.send(
            .get, "/api/v1/custom-product-page-localizations/cpl-1/placements?placement-type=APP_STORE_SEARCH_RESULTS_ASSET",
            placementRepo: placementRepo
        )

        #expect(status == .ok)
        #expect(body.contains(#""id":"pl-1""#))
        #expect(body.contains(#""placementType":"APP_STORE_SEARCH_RESULTS_ASSET""#))
    }

    // MARK: - Helpers

    static func send(
        _ method: HTTPRequest.Method,
        _ uri: String,
        body: String? = nil,
        placementRepo: MockAssetPlacementRepository
    ) async throws -> (HTTPResponse.Status, String) {
        let router = Router(context: BasicWebSocketRequestContext.self)
        AssetLibraryController(
            libraryRepo: MockAssetLibraryRepository(), imageRepo: MockLibraryImageRepository(),
            videoRepo: MockLibraryVideoRepository(), placementRepo: placementRepo
        ).addRoutes(to: router.group("/api/v1"))
        return try await Application(router: router).test(.router) { client in
            try await client.execute(
                uri: uri, method: method,
                headers: [.contentType: "application/json"],
                body: body.map { ByteBuffer(string: $0) }
            ) { response in
                (response.status, String(buffer: response.body).replacingOccurrences(of: "\\/", with: "/").replacingOccurrences(of: " ", with: ""))
            }
        }
    }
}

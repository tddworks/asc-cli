@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation
import Testing
@testable import Infrastructure

@Suite
struct SDKAssetLibraryRepositoryTests {

    // MARK: - getAssetLibrary

    @Test func `should tie the library to the app it was read from`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppAssetLibraryResponse(
            data: AppStoreConnect_Swift_SDK.AppAssetLibrary(type: .appAssetLibraries, id: "lib-1"),
            links: .init(this: "")
        ))

        let library = try await SDKAssetLibraryRepository(client: stub).getAssetLibrary(appId: "app-42")

        #expect(library == Domain.AppAssetLibrary(id: "lib-1", appId: "app-42"))
        #expect(stub.lastPath == "/v1/apps/app-42/assetLibrary")
    }

    // MARK: - listPlacementGroups

    @Test func `should list one row per placement type and group with its device, sizes and limit per feature`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.refData(Self.catalog))

        let groups = try await SDKAssetLibraryRepository(client: stub).listPlacementGroups(placementType: nil, feature: nil)

        #expect(groups == [
            AssetPlacementGroup(id: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", placementType: .appScreenshot,
                                platform: "IPHONE_APP_STORE", displayClass: "IPHONE_DYNAMIC_ISLAND_LARGE_DISPLAY",
                                feature: "APP_STORE_VERSIONS", sizes: ["1290x2796", "2796x1290"], maxCount: 10),
            AssetPlacementGroup(id: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", placementType: .appScreenshot,
                                platform: "IPHONE_APP_STORE", displayClass: "IPHONE_DYNAMIC_ISLAND_LARGE_DISPLAY",
                                feature: "CUSTOM_PRODUCT_PAGES", sizes: ["1290x2796", "2796x1290"], maxCount: 5),
            AssetPlacementGroup(id: "IPHONE_DUO_PROFILE", placementType: .appScreenshot,
                                platform: "IPHONE_APP_STORE", displayClass: "IPHONE_DUO",
                                feature: nil, sizes: ["1290x2796"], maxCount: nil),
            AssetPlacementGroup(id: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", placementType: .appPreview,
                                platform: "IPHONE_APP_STORE", displayClass: "IPHONE_DYNAMIC_ISLAND_LARGE_DISPLAY",
                                feature: "APP_STORE_VERSIONS", sizes: ["886x1920"], maxCount: 3),
        ])
    }

    @Test func `should only show the requested placement type and feature`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.refData(Self.catalog))

        let groups = try await SDKAssetLibraryRepository(client: stub)
            .listPlacementGroups(placementType: .appScreenshot, feature: "CUSTOM_PRODUCT_PAGES")

        #expect(groups == [
            AssetPlacementGroup(id: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", placementType: .appScreenshot,
                                platform: "IPHONE_APP_STORE", displayClass: "IPHONE_DYNAMIC_ISLAND_LARGE_DISPLAY",
                                feature: "CUSTOM_PRODUCT_PAGES", sizes: ["1290x2796", "2796x1290"], maxCount: 5),
        ])
    }

    @Test func `should ask App Store Connect's catalog for just the requested placement type and feature`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.refData(Self.catalog))

        _ = try await SDKAssetLibraryRepository(client: stub)
            .listPlacementGroups(placementType: .appScreenshot, feature: "APP_STORE_VERSIONS")

        #expect(stub.lastPath == "/v1/appAssetLibraryRefData")
        #expect(stub.lastQuery?.map { "\($0.0)=\($0.1 ?? "")" } == [
            "filter[placementTypes]=APP_SCREENSHOT", "filter[features]=APP_STORE_VERSIONS",
        ])
    }

    @Test func `should skip placement types asc does not know yet instead of failing`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.refData("""
        {"data":[{"type":"appAssetLibraryRefData","id":"ref","attributes":{
          "placementTypes":[{"placementTypeId":"HOLOGRAM_ASSET","specMappings":[{"placementGroupId":"HOLO","specs":[]}]}],
          "placementProfileGroups":[{"placementProfileGroupId":"HOLO","platform":"HOLO_STORE","displayClassId":"HOLO_DISPLAY"}]
        }}],"links":{"self":""}}
        """))

        let groups = try await SDKAssetLibraryRepository(client: stub).listPlacementGroups(placementType: nil, feature: nil)

        #expect(groups == [])
    }

    // MARK: - Fixtures

    static func refData(_ json: String) throws -> AssetRefDataDocument {
        try JSONDecoder().decode(AssetRefDataDocument.self, from: Data(json.utf8))
    }

    /// Shaped like Apple's `GET /v1/appAssetLibraryRefData`; display classes are strings asc doesn't enumerate.
    static let catalog = """
    {"data":[{"type":"appAssetLibraryRefData","id":"ref","attributes":{
      "features":[
        {"featureId":"APP_STORE_VERSIONS","placementPolicies":[
          {"placementType":"APP_SCREENSHOT","groupLimits":[{"groupIds":["IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"],"maxCount":10}]},
          {"placementType":"APP_PREVIEW","groupLimits":[{"groupIds":["IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"],"maxCount":3}]}
        ]},
        {"featureId":"CUSTOM_PRODUCT_PAGES","placementPolicies":[
          {"placementType":"APP_SCREENSHOT","groupLimits":[{"groupIds":["IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"],"maxCount":5}]}
        ]}
      ],
      "placementProfileGroups":[
        {"placementProfileGroupId":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","platform":"IPHONE_APP_STORE","displayClassId":"IPHONE_DYNAMIC_ISLAND_LARGE_DISPLAY"},
        {"placementProfileGroupId":"IPHONE_DUO_PROFILE","platform":"IPHONE_APP_STORE","displayClassId":"IPHONE_DUO"}
      ],
      "imageSpecs":[
        {"specId":"spec-portrait","dimensions":{"minWidth":1290,"maxWidth":1290,"minHeight":2796,"maxHeight":2796}},
        {"specId":"spec-landscape","dimensions":{"minWidth":2796,"maxWidth":2796,"minHeight":1290,"maxHeight":1290}}
      ],
      "videoSpecs":[
        {"specId":"spec-preview","dimensions":{"minWidth":886,"maxWidth":886,"minHeight":1920,"maxHeight":1920}}
      ],
      "placementTypes":[
        {"placementTypeId":"APP_SCREENSHOT","acceptsAssetCategories":["APP_SCREENSHOTS_AND_PREVIEWS"],"specMappings":[
          {"placementGroupId":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","specs":["spec-portrait","spec-landscape"]},
          {"placementGroupId":"IPHONE_DUO_PROFILE","specs":["spec-portrait"]}
        ]},
        {"placementTypeId":"APP_PREVIEW","acceptsAssetCategories":["APP_SCREENSHOTS_AND_PREVIEWS"],"specMappings":[
          {"placementGroupId":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","specs":["spec-preview"]}
        ]}
      ]
    }}],"links":{"self":""}}
    """
}

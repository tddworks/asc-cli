import Foundation
import Testing
@testable import Domain

@Suite
struct AssetPlacementGroupTests {

    @Test func `should show the group with its device, sizes and limit`() throws {
        let group = MockRepositoryFactory.makeAssetPlacementGroup(
            id: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", placementType: .appScreenshot,
            platform: "IPHONE_APP_STORE", displayClass: "IPHONE_DYNAMIC_ISLAND_LARGE_DISPLAY",
            feature: "APP_STORE_VERSIONS", sizes: ["1290x2796", "2796x1290"], maxCount: 10
        )

        #expect(try Self.json(group) == #"{"displayClass":"IPHONE_DYNAMIC_ISLAND_LARGE_DISPLAY","feature":"APP_STORE_VERSIONS","id":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","maxCount":10,"placementType":"APP_SCREENSHOT","platform":"IPHONE_APP_STORE","sizes":["1290x2796","2796x1290"]}"#)
    }

    @Test func `should leave out feature and limit when no feature caps the group`() throws {
        let group = MockRepositoryFactory.makeAssetPlacementGroup(
            id: "MAC_PROFILE", placementType: .appScreenshot, platform: nil, displayClass: nil,
            feature: nil, sizes: [], maxCount: nil
        )

        #expect(try Self.json(group) == #"{"id":"MAC_PROFILE","placementType":"APP_SCREENSHOT","sizes":[]}"#)
    }

    @Test func `should offer placing an asset into the group`() {
        let group = MockRepositoryFactory.makeAssetPlacementGroup(id: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", placementType: .appScreenshot)

        #expect(group.affordances == [
            "place": "asc asset-placements create --image-id <image-id> --localization-id <localization-id> --placement-group IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE --placement-type APP_SCREENSHOT",
        ])
    }

    @Test func `should show type, group, device, sizes and limit in a table`() {
        let group = MockRepositoryFactory.makeAssetPlacementGroup(sizes: ["1290x2796", "2796x1290"], maxCount: 10)

        #expect(AssetPlacementGroup.tableHeaders == ["Type", "Group", "Platform", "Display Class", "Feature", "Sizes", "Max"])
        #expect(group.tableRow == [
            "APP_SCREENSHOT", "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", "IPHONE_APP_STORE",
            "IPHONE_DYNAMIC_ISLAND_LARGE_DISPLAY", "APP_STORE_VERSIONS", "1290x2796, 2796x1290", "10",
        ])
    }

    static func json(_ value: some Encodable) throws -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(data: try encoder.encode(value), encoding: .utf8)
    }
}

import Foundation
import Testing
@testable import Domain

@Suite
struct ScreenshotImportGroupResultTests {

    private func result(
        localizationId: String? = "loc-1",
        status: ScreenshotImportStatus,
        placementGroup: String? = "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"
    ) -> ScreenshotImportGroupResult {
        ScreenshotImportGroupResult(
            locale: "en-US", localizationId: localizationId, versionId: localizationId.map { _ in "v-1" },
            placementGroup: placementGroup, status: status, placements: [ScreenshotImportPlacement(file: "en-US/1.png")]
        )
    }

    @Test func `should point to the localization's placements once it exists`() {
        #expect(result(status: .placed).affordances == [
            "listPlacements": "asc asset-placements list --localization-id loc-1",
        ])
        #expect(result(status: .placed).apiLinks["listPlacements"] == APILink(href: "/api/v1/version-localizations/loc-1/placements", method: "GET"))
    }

    @Test func `should point nowhere when the locale doesn't exist on the version yet`() {
        #expect(result(localizationId: nil, status: .planned).affordances == [:])
    }

    @Test func `should offer to replace the screenshots already there on a conflict`() {
        let conflict = result(status: .conflict)

        #expect(conflict.affordances["replace"] == "asc screenshots import --existing replace --from <zip> --to-library --version-id v-1")
        #expect(conflict.apiLinks["replace"] == APILink(href: "/api/v1/versions/v-1/screenshots/import", method: "POST"))
    }

    @Test func `should not offer to replace when nothing conflicts`() {
        #expect(result(status: .placed).affordances["replace"] == nil)
        #expect(result(status: .overLimit).affordances["replace"] == nil)
    }

    @Test func `should point to the screenshot placement groups when no group accepts the size`() {
        #expect(result(status: .noMatchingGroup, placementGroup: nil).affordances["listPlacementGroups"]
            == "asc asset-placement-groups list --placement-type APP_SCREENSHOT")
        #expect(result(status: .placed).affordances["listPlacementGroups"] == nil)
    }

    @Test func `should be a success only when planned or placed`() {
        #expect(ScreenshotImportStatus.allCases.filter(\.isSuccess) == [.planned, .placed])
    }

    @Test func `should leave out what it doesn't know`() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let json = String(decoding: try encoder.encode(result(localizationId: nil, status: .planned)), as: UTF8.self)

        #expect(json == #"{"locale":"en-US","placementGroup":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","placements":[{"file":"en-US\/1.png"}],"status":"planned"}"#)
    }

    @Test func `should show the ids and positions of what it placed`() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let placed = ScreenshotImportGroupResult(
            locale: "en-US", localizationId: "loc-1", versionId: "v-1", placementGroup: nil, status: .ambiguous,
            placements: [ScreenshotImportPlacement(file: "a.png", imageId: "img-1", placementId: "pl-1", position: 1)],
            message: "m", existingPlacementIds: ["pl-0"], candidates: ["A", "B"]
        )

        let json = String(decoding: try encoder.encode(placed), as: UTF8.self)

        #expect(json == #"{"candidates":["A","B"],"existingPlacementIds":["pl-0"],"locale":"en-US","localizationId":"loc-1","message":"m","placements":[{"file":"a.png","imageId":"img-1","placementId":"pl-1","position":1}],"status":"ambiguous"}"#)
    }
}

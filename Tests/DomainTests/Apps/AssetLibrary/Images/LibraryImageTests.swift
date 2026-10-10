import Foundation
import Testing
@testable import Domain

@Suite
struct LibraryImageTests {

    // MARK: - Schema

    @Test func `should belong to the library it was listed under and leave out what App Store Connect has not filled in`() throws {
        let image = MockRepositoryFactory.makeLibraryImage(
            id: "img-1", libraryId: "lib-9", fileName: "home.png", fileSize: 14619,
            category: .appScreenshotsAndPreviews, state: .awaitingUpload
        )

        #expect(try Self.json(image) == #"{"category":"APP_SCREENSHOTS_AND_PREVIEWS","fileName":"home.png","fileSize":14619,"id":"img-1","libraryId":"lib-9","state":"AWAITING_UPLOAD"}"#)
    }

    @Test func `should show the matched spec, dimensions and state details once processed`() throws {
        let image = MockRepositoryFactory.makeLibraryImage(
            id: "img-1", libraryId: "lib-9", fileName: "home.png", fileSize: 14619,
            category: .appScreenshotsAndPreviews, state: .failed,
            referenceName: "Home", specId: "spec-1", width: 1290, height: 2796,
            templateUrl: "https://example.com/{w}x{h}bb.{f}",
            stateDetails: [AssetStateDetail(code: "IMAGE_INCORRECT_DIMENSIONS", description: "Wrong size")],
            createdDate: "2026-08-11T22:44:12.019637Z"
        )

        #expect(try Self.json(image) == #"{"category":"APP_SCREENSHOTS_AND_PREVIEWS","createdDate":"2026-08-11T22:44:12.019637Z","fileName":"home.png","fileSize":14619,"height":2796,"id":"img-1","libraryId":"lib-9","referenceName":"Home","specId":"spec-1","state":"FAILED","stateDetails":[{"code":"IMAGE_INCORRECT_DIMENSIONS","description":"Wrong size"}],"templateUrl":"https://example.com/{w}x{h}bb.{f}","width":1290}"#)
    }

    // MARK: - Affordances

    @Test func `should offer placing a processed screenshot as an app screenshot`() {
        let image = MockRepositoryFactory.makeLibraryImage(id: "img-1", libraryId: "lib-1", category: .appScreenshotsAndPreviews, state: .prepareForSubmission)

        #expect(image.affordances == [
            "delete": "asc asset-images delete --image-id img-1",
            "listImages": "asc asset-images list --library-id lib-1",
            "listPlacements": "asc asset-placements list --image-id img-1",
            "place": "asc asset-placements create --image-id img-1 --localization-id <localization-id> --placement-group <placement-group> --placement-type APP_SCREENSHOT",
        ])
    }

    @Test func `should leave the placement type to the user when placing a creative asset`() {
        let image = MockRepositoryFactory.makeLibraryImage(id: "img-1", category: .creativeAssets, state: .prepareForSubmission)

        #expect(image.affordances["place"] == "asc asset-placements create --image-id img-1 --localization-id <localization-id> --placement-group <placement-group> --placement-type <placement-type>")
    }

    @Test func `should offer a refresh instead of placing while the upload is still being processed`() {
        let processing = MockRepositoryFactory.makeLibraryImage(id: "img-1", libraryId: "lib-1", state: .uploadComplete)
        let awaiting = MockRepositoryFactory.makeLibraryImage(id: "img-2", libraryId: "lib-1", state: .awaitingUpload)

        #expect(processing.affordances["place"] == nil)
        #expect(processing.affordances["refresh"] == "asc asset-images list --image-id img-1 --library-id lib-1")
        #expect(awaiting.affordances["place"] == nil)
        #expect(awaiting.affordances["refresh"] == "asc asset-images list --image-id img-2 --library-id lib-1")
    }

    @Test func `should offer neither placing nor refreshing when processing failed`() {
        let image = MockRepositoryFactory.makeLibraryImage(id: "img-1", state: .failed)

        #expect(image.affordances["place"] == nil)
        #expect(image.affordances["refresh"] == nil)
        #expect(image.affordances["delete"] == "asc asset-images delete --image-id img-1")
    }

    @Test func `should not offer delete while the image is in review`() {
        let image = MockRepositoryFactory.makeLibraryImage(id: "img-1", state: .inReview)

        #expect(image.affordances["delete"] == nil)
    }

    @Test func `should point to its placements, deletion and placing over REST`() {
        let image = MockRepositoryFactory.makeLibraryImage(id: "img-1", libraryId: "lib-1", state: .prepareForSubmission)

        #expect(image.apiLinks["listImages"] == APILink(href: "/api/v1/asset-library/lib-1/images", method: "GET"))
        #expect(image.apiLinks["listPlacements"] == APILink(href: "/api/v1/asset-images/img-1/placements", method: "GET"))
        #expect(image.apiLinks["delete"] == APILink(href: "/api/v1/asset-images/img-1", method: "DELETE"))
        #expect(image.apiLinks["place"] == APILink(href: "/api/v1/version-localizations/<localization-id>/placements", method: "POST"))
    }

    @Test func `should point a refresh at the library's images over REST while processing`() {
        let image = MockRepositoryFactory.makeLibraryImage(id: "img-1", libraryId: "lib-1", state: .uploadComplete)

        #expect(image.apiLinks["refresh"] == APILink(href: "/api/v1/asset-library/lib-1/images", method: "GET"))
    }

    @Test func `should offer archiving only once App Review approved the image`() {
        let approved = MockRepositoryFactory.makeLibraryImage(id: "img-1", libraryId: "lib-1", state: .approved)
        let processed = MockRepositoryFactory.makeLibraryImage(id: "img-2", state: .prepareForSubmission)

        #expect(approved.affordances["archive"] == "asc asset-images update --archived true --image-id img-1 --library-id lib-1")
        #expect(approved.apiLinks["archive"] == APILink(href: "/api/v1/asset-images/img-1", method: "PATCH"))
        #expect(processed.affordances["archive"] == nil)
    }

    // MARK: - Table

    @Test func `should show file, category, state and reference name in a table`() {
        let image = MockRepositoryFactory.makeLibraryImage(
            id: "img-1", fileName: "home.png", category: .appScreenshotsAndPreviews, state: .approved, referenceName: "Home"
        )

        #expect(LibraryImage.tableHeaders == ["ID", "File Name", "Category", "State", "Reference Name"])
        #expect(image.tableRow == ["img-1", "home.png", "APP_SCREENSHOTS_AND_PREVIEWS", "APPROVED", "Home"])
    }

    static func json(_ value: some Encodable) throws -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(data: try encoder.encode(value), encoding: .utf8)
    }
}

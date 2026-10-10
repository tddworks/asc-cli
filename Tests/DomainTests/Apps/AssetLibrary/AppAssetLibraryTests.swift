import Foundation
import Testing
@testable import Domain

@Suite
struct AppAssetLibraryTests {

    @Test func `should belong to the app it was read from`() throws {
        let library = MockRepositoryFactory.makeAssetLibrary(id: "lib-1", appId: "app-42")

        let json = try String(data: Self.encoder.encode(library), encoding: .utf8)

        #expect(json == #"{"appId":"app-42","id":"lib-1"}"#)
    }

    @Test func `should point to its images, placement groups and image upload on the CLI`() {
        let library = MockRepositoryFactory.makeAssetLibrary(id: "lib-1", appId: "app-42")

        #expect(library.affordances == [
            "listImages": "asc asset-images list --library-id lib-1",
            "listPlacementGroups": "asc asset-placement-groups list --placement-type APP_SCREENSHOT",
            "uploadImage": "asc asset-images upload --file <file> --library-id lib-1",
        ])
    }

    @Test func `should point to its images, placement groups and image upload over REST`() {
        let library = MockRepositoryFactory.makeAssetLibrary(id: "lib-1", appId: "app-42")

        #expect(library.apiLinks["listImages"] == APILink(href: "/api/v1/asset-library/lib-1/images", method: "GET"))
        #expect(library.apiLinks["listPlacementGroups"] == APILink(href: "/api/v1/asset-placement-groups", method: "GET"))
        #expect(library.apiLinks["uploadImage"] == APILink(href: "/api/v1/asset-library/lib-1/images", method: "POST"))
    }

    @Test func `should show its id and app in a table`() {
        let library = MockRepositoryFactory.makeAssetLibrary(id: "lib-1", appId: "app-42")

        #expect(AppAssetLibrary.tableHeaders == ["ID", "App ID"])
        #expect(library.tableRow == ["lib-1", "app-42"])
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}

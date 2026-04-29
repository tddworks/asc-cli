import Foundation
import Testing
@testable import Domain

@Suite
struct AppBundleTests {

    @Test func `app bundle carries all fields`() {
        let bundle = MockRepositoryFactory.makeAppBundle(
            id: "123",
            name: "My App",
            bundleId: "com.example.app",
            sku: "MYSKU",
            primaryLocale: "en-US",
            platforms: ["IOS"]
        )
        #expect(bundle.id == "123")
        #expect(bundle.name == "My App")
        #expect(bundle.bundleId == "com.example.app")
        #expect(bundle.sku == "MYSKU")
        #expect(bundle.primaryLocale == "en-US")
        #expect(bundle.platforms == ["IOS"])
    }

    @Test func `app bundle affordances include list versions`() {
        let bundle = MockRepositoryFactory.makeAppBundle(id: "app-1")
        #expect(bundle.affordances["listVersions"] == "asc versions list --app-id app-1")
    }

    @Test func `app bundle affordances include list app infos`() {
        let bundle = MockRepositoryFactory.makeAppBundle(id: "app-1")
        #expect(bundle.affordances["listAppInfos"] == "asc app-infos list --app-id app-1")
    }

    @Test func `app bundle is codable`() throws {
        let bundle = MockRepositoryFactory.makeAppBundle(
            id: "app-1",
            name: "Test",
            bundleId: "com.test",
            sku: "SKU1",
            primaryLocale: "en-US",
            platforms: ["IOS"]
        )
        let data = try JSONEncoder().encode(bundle)
        let decoded = try JSONDecoder().decode(AppBundle.self, from: data)
        #expect(decoded == bundle)
    }

    @Test func `app bundle table headers describe identity and platforms`() {
        #expect(AppBundle.tableHeaders == ["ID", "Name", "Bundle ID", "SKU", "Platforms"])
    }

    @Test func `app bundle table row joins multiple platforms with comma`() {
        let bundle = MockRepositoryFactory.makeAppBundle(
            id: "app-1",
            name: "Test",
            bundleId: "com.test",
            sku: "SKU1",
            primaryLocale: "en-US",
            platforms: ["IOS", "MAC_OS"]
        )
        #expect(bundle.tableRow == ["app-1", "Test", "com.test", "SKU1", "IOS,MAC_OS"])
    }

    @Test func `app bundle table row leaves platforms empty when none declared`() {
        let bundle = MockRepositoryFactory.makeAppBundle(
            id: "app-1",
            name: "Test",
            bundleId: "com.test",
            sku: "SKU1",
            primaryLocale: "en-US",
            platforms: []
        )
        #expect(bundle.tableRow[4] == "")
    }
}

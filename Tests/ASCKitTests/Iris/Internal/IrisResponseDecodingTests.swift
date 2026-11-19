import Foundation
import Testing
@testable import ASCKit

@Suite
struct IrisResponseDecodingTests {

    // MARK: - List response

    @Test func `decodes app bundles list response`() throws {
        let json = """
        {
          "data": [
            {
              "id": "123",
              "type": "appBundles",
              "attributes": {
                "name": "My App",
                "bundleId": "com.example.app",
                "sku": "MYSKU",
                "primaryLocale": "en-US",
                "platformNames": ["IOS"]
              }
            }
          ]
        }
        """
        let response = try JSONDecoder().decode(IrisAppBundlesResponse.self, from: Data(json.utf8))
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "123")
        #expect(response.data[0].attributes.name == "My App")
        #expect(response.data[0].attributes.bundleId == "com.example.app")
        #expect(response.data[0].attributes.platformNames == ["IOS"])
    }

    @Test func `decodes empty list response`() throws {
        let json = """
        { "data": [] }
        """
        let response = try JSONDecoder().decode(IrisAppBundlesResponse.self, from: Data(json.utf8))
        #expect(response.data.isEmpty)
    }

    // MARK: - Single response

    @Test func `decodes single app bundle response`() throws {
        let json = """
        {
          "data": {
            "id": "456",
            "type": "apps",
            "attributes": {
              "name": "New App",
              "bundleId": "com.example.new",
              "sku": "NEWSKU",
              "primaryLocale": "zh-Hans",
              "platformNames": ["IOS", "MAC_OS"]
            }
          }
        }
        """
        let response = try JSONDecoder().decode(IrisSingleAppBundleResponse.self, from: Data(json.utf8))
        #expect(response.data.id == "456")
        #expect(response.data.attributes.platformNames == ["IOS", "MAC_OS"])
    }

    // MARK: - Nil attributes

    @Test func `decodes response with nil optional attributes`() throws {
        let json = """
        {
          "data": {
            "id": "789",
            "type": "apps",
            "attributes": {}
          }
        }
        """
        let response = try JSONDecoder().decode(IrisSingleAppBundleResponse.self, from: Data(json.utf8))
        #expect(response.data.attributes.name == nil)
        #expect(response.data.attributes.bundleId == nil)
        #expect(response.data.attributes.sku == nil)
        #expect(response.data.attributes.primaryLocale == nil)
        #expect(response.data.attributes.platformNames == nil)
    }

    // MARK: - mapToAppBundle

    @Test func `maps resource to AppBundle with all fields`() {
        let repo = IrisSDKAppBundleRepository()
        let resource = makeResource(
            id: "app-1",
            name: "Test",
            bundleId: "com.test",
            sku: "SKU",
            primaryLocale: "en-US",
            platformNames: ["IOS"]
        )
        let bundle = repo.mapToAppBundle(resource)
        #expect(bundle.id == "app-1")
        #expect(bundle.name == "Test")
        #expect(bundle.bundleId == "com.test")
        #expect(bundle.sku == "SKU")
        #expect(bundle.primaryLocale == "en-US")
        #expect(bundle.platforms == ["IOS"])
    }

    @Test func `maps resource with nil name uses fallback`() {
        let repo = IrisSDKAppBundleRepository()
        let resource = makeResource(id: "app-1")
        let bundle = repo.mapToAppBundle(resource, fallbackName: "Fallback")
        #expect(bundle.name == "Fallback")
    }

    @Test func `maps resource with nil name and no fallback uses empty string`() {
        let repo = IrisSDKAppBundleRepository()
        let resource = makeResource(id: "app-1")
        let bundle = repo.mapToAppBundle(resource)
        #expect(bundle.name == "")
    }

    @Test func `maps resource with nil platforms uses empty array`() {
        let repo = IrisSDKAppBundleRepository()
        let resource = makeResource(id: "app-1")
        let bundle = repo.mapToAppBundle(resource)
        #expect(bundle.platforms == [])
    }

    @Test func `maps resource with nil primaryLocale defaults to en-US`() {
        let repo = IrisSDKAppBundleRepository()
        let resource = makeResource(id: "app-1")
        let bundle = repo.mapToAppBundle(resource)
        #expect(bundle.primaryLocale == "en-US")
    }

    // MARK: - Helpers

    private func makeResource(
        id: String,
        name: String? = nil,
        bundleId: String? = nil,
        sku: String? = nil,
        primaryLocale: String? = nil,
        platformNames: [String]? = nil
    ) -> IrisAppBundleResource {
        IrisAppBundleResource(
            id: id,
            type: "apps",
            attributes: IrisAppBundleAttributes(
                name: name,
                bundleId: bundleId,
                sku: sku,
                primaryLocale: primaryLocale,
                platformNames: platformNames
            )
        )
    }
}

import Foundation
import Testing
@testable import ASCKit

@Suite
struct AppCreateRequestTests {

    @Test func `request encodes app type with sku bundleId and primaryLocale`() throws {
        let request = AppCreateRequest.make(
            name: "My App", bundleId: "com.example.app",
            sku: "MYSKU", primaryLocale: "en-US",
            platforms: ["IOS"], versionString: "1.0"
        )
        let root = try encodeAndParse(request)
        let data = try #require(root["data"] as? [String: Any])
        #expect(data["type"] as? String == "apps")

        let attrs = try #require(data["attributes"] as? [String: Any])
        #expect(attrs["sku"] as? String == "MYSKU")
        #expect(attrs["bundleId"] as? String == "com.example.app")
        #expect(attrs["primaryLocale"] as? String == "en-US")
    }

    @Test func `included contains appStoreVersion with platform and versionString`() throws {
        let request = AppCreateRequest.make(
            name: "My App", bundleId: "com.example.app",
            sku: "MYSKU", primaryLocale: "en-US",
            platforms: ["IOS"], versionString: "2.0"
        )
        let root = try encodeAndParse(request)
        let included = try #require(root["included"] as? [[String: Any]])
        let version = try #require(included.first { $0["type"] as? String == "appStoreVersions" })
        let attrs = try #require(version["attributes"] as? [String: String])
        #expect(attrs["platform"] == "IOS")
        #expect(attrs["versionString"] == "2.0")
    }

    @Test func `included contains appInfoLocalization with name`() throws {
        let request = AppCreateRequest.make(
            name: "ASC CLI", bundleId: "com.example.app",
            sku: "MYSKU", primaryLocale: "en-US",
            platforms: ["IOS"], versionString: "1.0"
        )
        let root = try encodeAndParse(request)
        let included = try #require(root["included"] as? [[String: Any]])
        let infoLoc = try #require(included.first { $0["type"] as? String == "appInfoLocalizations" })
        let attrs = try #require(infoLoc["attributes"] as? [String: String])
        #expect(attrs["name"] == "ASC CLI")
        #expect(attrs["locale"] == "en-US")
    }

    @Test func `multi-platform app creates one version per platform`() throws {
        let request = AppCreateRequest.make(
            name: "My App", bundleId: "com.example.app",
            sku: "MYSKU", primaryLocale: "en-US",
            platforms: ["IOS", "MAC_OS"], versionString: "1.0"
        )
        let root = try encodeAndParse(request)
        let included = try #require(root["included"] as? [[String: Any]])
        let versions = included.filter { $0["type"] as? String == "appStoreVersions" }
        #expect(versions.count == 2)

        let platforms = versions.compactMap { ($0["attributes"] as? [String: String])?["platform"] }
        #expect(platforms.contains("IOS"))
        #expect(platforms.contains("MAC_OS"))
    }

    @Test func `relationships reference included resources by id`() throws {
        let request = AppCreateRequest.make(
            name: "My App", bundleId: "com.example.app",
            sku: "MYSKU", primaryLocale: "en-US",
            platforms: ["IOS"], versionString: "1.0"
        )
        let root = try encodeAndParse(request)
        let data = try #require(root["data"] as? [String: Any])
        let rels = try #require(data["relationships"] as? [String: Any])

        let versionsRel = try #require(rels["appStoreVersions"] as? [String: Any])
        let versionsData = try #require(versionsRel["data"] as? [[String: String]])
        let versionRefId = try #require(versionsData.first?["id"])

        let included = try #require(root["included"] as? [[String: Any]])
        let match = included.first { $0["id"] as? String == versionRefId }
        #expect(match != nil)
        #expect(match?["type"] as? String == "appStoreVersions")
    }

    // MARK: - Helper

    private func encodeAndParse<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

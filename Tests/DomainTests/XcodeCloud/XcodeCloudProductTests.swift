import Foundation
import Testing
@testable import Domain

@Suite
struct XcodeCloudProductTests {

    @Test func `product carries app id`() {
        let product = MockRepositoryFactory.makeXcodeCloudProduct(id: "prod-1", appId: "app-42")
        #expect(product.appId == "app-42")
    }

    @Test func `product affordances include listWorkflows command`() {
        let product = MockRepositoryFactory.makeXcodeCloudProduct(id: "prod-1", appId: "app-1")
        #expect(product.affordances["listWorkflows"] == "asc xcode-cloud workflows list --product-id prod-1")
    }

    @Test func `product affordances include listProducts command`() {
        let product = MockRepositoryFactory.makeXcodeCloudProduct(id: "prod-1", appId: "app-42")
        #expect(product.affordances["listProducts"] == "asc xcode-cloud products list --app-id app-42")
    }

    @Test func `product type raw values match ASC API values`() {
        #expect(XcodeCloudProductType.app.rawValue == "APP")
        #expect(XcodeCloudProductType.framework.rawValue == "FRAMEWORK")
    }

    @Test func `created date is omitted from json when nil`() throws {
        let product = XcodeCloudProduct(id: "p-1", appId: "a-1", name: "My App", productType: .app, createdDate: nil)
        let data = try JSONEncoder().encode(product)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("createdDate"))
    }

    @Test func `decode round-trip preserves all fields`() throws {
        let original = MockRepositoryFactory.makeXcodeCloudProduct(id: "prod-1", appId: "app-1", name: "Test App", productType: .framework)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XcodeCloudProduct.self, from: data)
        #expect(decoded.id == "prod-1")
        #expect(decoded.appId == "app-1")
        #expect(decoded.name == "Test App")
        #expect(decoded.productType == .framework)
    }
}

import Foundation
import Testing
@testable import Domain

@Suite
struct AppTests {

    @Test
    func `app has correct properties`() {
        let app = App(
            id: "123",
            name: "My App",
            bundleId: "com.example.app",
            sku: "SKU001",
            primaryLocale: "en-US"
        )
        #expect(app.id == "123")
        #expect(app.name == "My App")
        #expect(app.bundleId == "com.example.app")
        #expect(app.sku == "SKU001")
        #expect(app.primaryLocale == "en-US")
    }

    @Test
    func `display name returns name when present`() {
        let app = App(id: "1", name: "My App", bundleId: "com.example.app")
        #expect(app.displayName == "My App")
    }

    @Test
    func `display name falls back to bundle id when name is empty`() {
        let app = App(id: "1", name: "", bundleId: "com.example.app")
        #expect(app.displayName == "com.example.app")
    }

    @Test
    func `app is equatable`() {
        let a = App(id: "1", name: "App", bundleId: "com.test")
        let b = App(id: "1", name: "App", bundleId: "com.test")
        #expect(a == b)
    }

    @Test
    func `app is codable`() throws {
        let app = App(id: "1", name: "Test", bundleId: "com.test", sku: "SKU")
        let data = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(App.self, from: data)
        #expect(decoded == app)
    }
}

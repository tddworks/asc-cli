import Foundation
import Testing
@testable import Domain

@Suite
struct AppTests {

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
}

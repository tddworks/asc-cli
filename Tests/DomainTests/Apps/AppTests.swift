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

    @Test
    func `registryProperties includes app name`() {
        let app = App(id: "1", name: "My App", bundleId: "com.example.app")
        #expect(app.registryProperties["name"] == "My App")
    }

    @Test
    func `content rights declaration encodes to ASC API raw value`() {
        #expect(ContentRightsDeclaration.usesThirdPartyContent.rawValue == "USES_THIRD_PARTY_CONTENT")
        #expect(ContentRightsDeclaration.doesNotUseThirdPartyContent.rawValue == "DOES_NOT_USE_THIRD_PARTY_CONTENT")
    }

    @Test
    func `app with content rights declaration round-trips through JSON`() throws {
        let app = App(id: "1", name: "X", bundleId: "com.x", contentRightsDeclaration: .doesNotUseThirdPartyContent)
        let data = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(App.self, from: data)
        #expect(decoded.contentRightsDeclaration == .doesNotUseThirdPartyContent)
    }

    @Test
    func `app without content rights declaration omits the field from JSON`() throws {
        let app = App(id: "1", name: "X", bundleId: "com.x")
        let data = try JSONEncoder().encode(app)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(!json.contains("contentRightsDeclaration"))
    }
}

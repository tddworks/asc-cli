import Foundation
import Testing
@testable import Domain

@Suite
struct AppIconTests {

    @Test
    func `app carries optional icon asset`() {
        let asset = ImageAsset(templateUrl: "https://cdn.example.com/x/{w}x{h}bb.{f}", width: 1024, height: 1024)
        let app = App(id: "1", name: "My App", bundleId: "com.example.app", iconAsset: asset)
        #expect(app.iconAsset == asset)
    }

    @Test
    func `app with icon asset copies other fields`() {
        let asset = ImageAsset(templateUrl: "https://cdn.example.com/x/{w}x{h}bb.{f}", width: 512, height: 512)
        let app = App(id: "1", name: "My App", bundleId: "com.example.app")
        let enriched = app.with(iconAsset: asset)
        #expect(enriched.id == "1")
        #expect(enriched.name == "My App")
        #expect(enriched.bundleId == "com.example.app")
        #expect(enriched.iconAsset == asset)
    }

    @Test
    func `app without icon asset omits field from JSON`() throws {
        let app = App(id: "1", name: "My App", bundleId: "com.example.app")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(app)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(!json.contains("iconAsset"))
    }

    @Test
    func `app with icon asset encodes templateUrl width and height`() throws {
        let asset = ImageAsset(templateUrl: "https://cdn.example.com/x/{w}x{h}bb.{f}", width: 1024, height: 1024)
        let app = App(id: "1", name: "My App", bundleId: "com.example.app", iconAsset: asset)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(app)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("\"iconAsset\""))
        #expect(json.contains("\"width\":1024"))
        #expect(json.contains("\"height\":1024"))
    }
}
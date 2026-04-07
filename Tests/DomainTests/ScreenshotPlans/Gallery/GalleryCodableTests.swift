import Foundation
import Testing
@testable import Domain

@Suite("Gallery Codable")
struct GalleryCodableTests {

    // ── User: "I can save and load a gallery template as JSON" ──

    @Test func `screen template round-trips through JSON`() throws {
        let template = ScreenTemplate(
            headline: TextSlot(y: 0.02, size: 0.10, weight: 900, align: "center"),
            device: DeviceSlot(y: 0.15, width: 0.85),
            decorations: [
                Decoration(shape: .gem, x: 0.9, y: 0.06, size: 0.06)
            ]
        )
        let data = try JSONEncoder().encode(template)
        let decoded = try JSONDecoder().decode(ScreenTemplate.self, from: data)
        #expect(decoded == template)
    }

    @Test func `screen template without device round-trips`() throws {
        let hero = ScreenTemplate(
            headline: TextSlot(y: 0.25, size: 0.12)
        )
        let data = try JSONEncoder().encode(hero)
        let decoded = try JSONDecoder().decode(ScreenTemplate.self, from: data)
        #expect(decoded.device == nil)
        #expect(decoded.headline.size == 0.12)
    }

    @Test func `gallery template round-trips through JSON`() throws {
        let template = GalleryTemplate(
            id: "neon-pop",
            name: "Neon Pop",
            screens: [
                .hero: ScreenTemplate(headline: TextSlot(y: 0.25, size: 0.08)),
                .feature: ScreenTemplate(
                    headline: TextSlot(y: 0.02, size: 0.10),
                    device: DeviceSlot(y: 0.36, width: 0.68)
                ),
            ]
        )
        let data = try JSONEncoder().encode(template)
        let decoded = try JSONDecoder().decode(GalleryTemplate.self, from: data)
        #expect(decoded.id == "neon-pop")
        #expect(decoded.screens[.hero]?.device == nil)
        #expect(decoded.screens[.feature]?.device?.width == 0.68)
    }

    @Test func `gallery palette round-trips through JSON`() throws {
        let palette = GalleryPalette(
            id: "green-mint",
            name: "Green Mint",
            background: "linear-gradient(135deg, #c4f7a0, #a0f7e0)"
        )
        let data = try JSONEncoder().encode(palette)
        let decoded = try JSONDecoder().decode(GalleryPalette.self, from: data)
        #expect(decoded == palette)
    }

    @Test func `decoration round-trips through JSON`() throws {
        let deco = Decoration(shape: .gem, x: 0.9, y: 0.06, size: 0.06, opacity: 0.8)
        let data = try JSONEncoder().encode(deco)
        let decoded = try JSONDecoder().decode(Decoration.self, from: data)
        #expect(decoded == deco)
    }

    // ── User: "I can decode a gallery template from a JSON file" ──

    @Test func `gallery template decodes from JSON string`() throws {
        let json = """
        {
          "id": "neon-pop",
          "name": "Neon Pop",
          "screens": {
            "hero": {
              "headline": { "y": 0.25, "size": 0.08, "weight": 900, "align": "left" }
            },
            "feature": {
              "headline": { "y": 0.02, "size": 0.10, "weight": 900, "align": "center" },
              "device": { "x": 0.5, "y": 0.36, "width": 0.68 }
            }
          }
        }
        """
        let template = try JSONDecoder().decode(GalleryTemplate.self, from: Data(json.utf8))
        #expect(template.id == "neon-pop")
        #expect(template.screens.count == 2)
        #expect(template.screens[.hero]?.headline.align == "left")
        #expect(template.screens[.feature]?.device?.width == 0.68)
    }
}

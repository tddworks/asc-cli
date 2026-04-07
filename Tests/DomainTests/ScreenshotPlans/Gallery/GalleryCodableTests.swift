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

    // ── User: "I can save and load a Gallery as JSON" ──

    @Test func `gallery round-trips through JSON`() throws {
        let gallery = Gallery(appName: "BezelBlend", screenshots: ["s0.png", "s1.png"])
        gallery.appShots[0].tagline = "BEZELBLEND"
        gallery.appShots[0].headline = "PREMIUM\nDEVICE\nMOCKUPS."
        gallery.appShots[0].badges = ["iPhone 17"]
        gallery.appShots[0].trustMarks = ["4.9 STARS"]
        gallery.appShots[1].tagline = "BACKGROUNDS"
        gallery.appShots[1].headline = "CUSTOMIZE\nEVERY DETAIL"
        gallery.appShots[1].body = "Pick from solid colors."
        gallery.appShots[1].badges = ["Mesh"]
        gallery.template = GalleryTemplate(
            id: "neon-pop", name: "Neon Pop",
            background: "linear-gradient(165deg, #a8ff78, #78ffd6)",
            screens: [
                .hero: ScreenTemplate(headline: TextSlot(y: 0.07, size: 0.08, weight: 900, align: "left")),
                .feature: ScreenTemplate(headline: TextSlot(y: 0.05, size: 0.08), device: DeviceSlot(y: 0.36, width: 0.68)),
            ]
        )
        gallery.palette = GalleryPalette(id: "green", name: "Green", background: "linear-gradient(165deg, #a8ff78, #78ffd6)")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(gallery)
        let decoded = try JSONDecoder().decode(Gallery.self, from: data)

        #expect(decoded.appName == "BezelBlend")
        #expect(decoded.appShots.count == 2)
        #expect(decoded.appShots[0].tagline == "BEZELBLEND")
        #expect(decoded.appShots[0].headline == "PREMIUM\nDEVICE\nMOCKUPS.")
        #expect(decoded.appShots[0].badges == ["iPhone 17"])
        #expect(decoded.appShots[0].trustMarks == ["4.9 STARS"])
        #expect(decoded.appShots[0].type == .hero)
        #expect(decoded.appShots[1].tagline == "BACKGROUNDS")
        #expect(decoded.appShots[1].body == "Pick from solid colors.")
        #expect(decoded.template?.id == "neon-pop")
        #expect(decoded.palette?.background.contains("#a8ff78") == true)
    }

    @Test func `gallery decodes from JSON file format`() throws {
        let json = """
        {
          "appName": "BezelBlend",
          "template": {
            "id": "neon-pop",
            "name": "Neon Pop",
            "background": "linear-gradient(165deg, #a8ff78, #78ffd6)",
            "screens": {
              "hero": { "headline": { "y": 0.07, "size": 0.08, "weight": 900, "align": "left" } },
              "feature": { "headline": { "y": 0.05, "size": 0.08, "weight": 900, "align": "left" }, "device": { "x": 0.5, "y": 0.36, "width": 0.68 } }
            }
          },
          "palette": { "id": "green", "name": "Green", "background": "linear-gradient(165deg, #a8ff78, #78ffd6)" },
          "appShots": [
            { "screenshot": "s0.png", "type": "hero", "tagline": "BEZELBLEND", "headline": "PREMIUM\\nDEVICE\\nMOCKUPS.", "badges": ["iPhone 17", "Ultra 3"], "trustMarks": ["4.9 STARS", "PRO QUALITY"] },
            { "screenshot": "s1.png", "type": "feature", "tagline": "BACKGROUNDS", "headline": "CUSTOMIZE\\nEVERY DETAIL", "body": "Pick from solid colors.", "badges": ["Mesh", "Gradient"] }
          ]
        }
        """
        let gallery = try JSONDecoder().decode(Gallery.self, from: Data(json.utf8))
        #expect(gallery.appName == "BezelBlend")
        #expect(gallery.appShots.count == 2)
        #expect(gallery.appShots[0].type == .hero)
        #expect(gallery.appShots[0].headline == "PREMIUM\nDEVICE\nMOCKUPS.")
        #expect(gallery.appShots[1].type == .feature)
        #expect(gallery.appShots[1].body == "Pick from solid colors.")
        #expect(gallery.template?.id == "neon-pop")
        #expect(gallery.template?.background.contains("#a8ff78") == true)
    }

    @Test func `array of galleries decodes — gallery-templates.json format`() throws {
        let json = """
        [
          {
            "appName": "BezelBlend",
            "template": { "id": "neon-pop", "name": "Neon Pop", "background": "#a8ff78", "screens": { "hero": { "headline": { "y": 0.07, "size": 0.08, "weight": 900, "align": "left" } } } },
            "palette": { "id": "g", "name": "G", "background": "#a8ff78" },
            "appShots": [
              { "screenshot": "s0.png", "type": "hero", "headline": "HERO" }
            ]
          },
          {
            "appName": "BezelBlend",
            "template": { "id": "blue-depth", "name": "Blue Depth", "background": "#edf1f8", "screens": { "hero": { "headline": { "y": 0.04, "size": 0.11, "weight": 900, "align": "center" } } } },
            "palette": { "id": "b", "name": "B", "background": "#edf1f8" },
            "appShots": [
              { "screenshot": "s0.png", "type": "hero", "headline": "BezelBlend" }
            ]
          }
        ]
        """
        let galleries = try JSONDecoder().decode([Gallery].self, from: Data(json.utf8))
        #expect(galleries.count == 2)
        #expect(galleries[0].template?.id == "neon-pop")
        #expect(galleries[0].appShots[0].headline == "HERO")
        #expect(galleries[1].template?.id == "blue-depth")
        #expect(galleries[1].appShots[0].headline == "BezelBlend")
    }

    @Test func `array of gallery templates decodes from JSON`() throws {
        let json = """
        [
          {
            "id": "neon-pop",
            "name": "Neon Pop",
            "screens": {
              "hero": { "headline": { "y": 0.07, "size": 0.08, "weight": 900, "align": "left" } },
              "feature": {
                "headline": { "y": 0.05, "size": 0.08, "weight": 900, "align": "left" },
                "device": { "x": 0.5, "y": 0.36, "width": 0.68 }
              }
            }
          },
          {
            "id": "blue-depth",
            "name": "Blue Depth",
            "screens": {
              "hero": { "headline": { "y": 0.04, "size": 0.11, "weight": 900, "align": "center" } },
              "feature": {
                "headline": { "y": 0.025, "size": 0.11, "weight": 900, "align": "center" },
                "device": { "x": 0.5, "y": 0.14, "width": 0.82 }
              }
            }
          }
        ]
        """
        let templates = try JSONDecoder().decode([GalleryTemplate].self, from: Data(json.utf8))
        #expect(templates.count == 2)
        #expect(templates[0].id == "neon-pop")
        #expect(templates[1].id == "blue-depth")
        #expect(templates[1].screens[.feature]?.device?.width == 0.82)
    }
}

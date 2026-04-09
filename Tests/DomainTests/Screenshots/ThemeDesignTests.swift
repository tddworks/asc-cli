import Foundation
import Testing
@testable import Domain

@Suite("ThemeDesign")
struct ThemeDesignTests {

    // MARK: - Codable

    @Test func `theme design is codable`() throws {
        let design = ThemeDesign(
            palette: GalleryPalette(id: "space", name: "Space",
                                     background: "linear-gradient(135deg, #0f172a, #7c3aed)",
                                     textColor: "#e0e7ff"),
            decorations: [
                Decoration(shape: .label("✨"), x: 0.85, y: 0.12, size: 0.04, opacity: 0.6,
                           color: "#fff", background: "rgba(255,255,255,0.1)",
                           borderRadius: "50%", animation: .twinkle),
            ]
        )
        let data = try JSONEncoder().encode(design)
        let decoded = try JSONDecoder().decode(ThemeDesign.self, from: data)
        #expect(decoded == design)
        #expect(decoded.palette.textColor == "#e0e7ff")
        #expect(decoded.decorations.count == 1)
        #expect(decoded.decorations[0].shape == .label("✨"))
    }

    @Test func `theme design with empty decorations is valid`() throws {
        let design = ThemeDesign(
            palette: GalleryPalette(id: "minimal", name: "Minimal", background: "#000", textColor: "#fff"),
            decorations: []
        )
        let data = try JSONEncoder().encode(design)
        let decoded = try JSONDecoder().decode(ThemeDesign.self, from: data)
        #expect(decoded.decorations.isEmpty)
        #expect(decoded.palette.background == "#000")
    }

    @Test func `theme design decodes from AI JSON format`() throws {
        let json = """
        {
            "palette": {
                "id": "space",
                "name": "Space",
                "background": "linear-gradient(135deg, #0f172a, #7c3aed)",
                "textColor": "#ffffff"
            },
            "decorations": [
                {
                    "shape": {"label": "✨"},
                    "x": 0.85,
                    "y": 0.12,
                    "size": 0.03,
                    "opacity": 0.6,
                    "color": "#ffffff",
                    "background": "rgba(255,255,255,0.15)",
                    "borderRadius": "50%",
                    "animation": "twinkle"
                }
            ]
        }
        """.data(using: .utf8)!
        let design = try JSONDecoder().decode(ThemeDesign.self, from: json)
        #expect(design.palette.background.contains("#0f172a"))
        #expect(design.palette.textColor == "#ffffff")
        #expect(design.decorations.count == 1)
        #expect(design.decorations[0].animation == .twinkle)
        #expect(design.decorations[0].x == 0.85)
    }

    @Test func `theme design palette without textColor defaults to nil`() throws {
        let json = """
        {
            "palette": {"id": "p", "name": "P", "background": "#111"},
            "decorations": []
        }
        """.data(using: .utf8)!
        let design = try JSONDecoder().decode(ThemeDesign.self, from: json)
        #expect(design.palette.textColor == nil)
    }
}

import Foundation
import Testing
@testable import Domain

@Suite("Gallery Preview HTML")
struct GalleryPreviewTests {

    @Test func `gallery template generates previewHTML`() {
        let template = GalleryTemplate(
            id: "neon-pop",
            name: "Neon Pop",
            description: "Vibrant green gradient",
            background: "linear-gradient(165deg, #a8ff78, #78ffd6)",
            screens: [
                .feature: ScreenTemplate(
                    headline: TextSlot(y: 0.05, size: 0.08, weight: 900, align: "left"),
                    device: DeviceSlot(y: 0.36, width: 0.68)
                ),
            ]
        )
        let html = template.previewHTML
        // Must not be empty
        #expect(!html.isEmpty)
        // Must be a full HTML page
        #expect(html.contains("<!DOCTYPE html>"))
        // Must contain the template name as preview text
        #expect(html.contains("Neon Pop"))
        // Must contain the actual background color
        #expect(html.contains("linear-gradient"))
        #expect(html.contains("#a8ff78"))
        // Must contain the wireframe phone structure
        #expect(html.contains("9:41"))  // status bar time
    }

    @Test func `gallery template with dark background uses light text`() {
        let template = GalleryTemplate(
            id: "cosmic",
            name: "Cosmic",
            background: "linear-gradient(170deg, #0f0c29, #302b63)",
            screens: [
                .feature: ScreenTemplate(
                    headline: TextSlot(y: 0.05, size: 0.078, weight: 800, align: "left"),
                    device: DeviceSlot(y: 0.36, width: 0.68)
                ),
            ]
        )
        let html = template.previewHTML
        #expect(html.contains("Cosmic"))
        #expect(html.contains("#0f0c29"))
        // Dark bg → light text
        #expect(html.contains("#FFFFFF"))
    }

    @Test func `gallery template with light background uses dark text`() {
        let template = GalleryTemplate(
            id: "neon-pop",
            name: "Neon Pop",
            background: "linear-gradient(165deg, #a8ff78, #78ffd6)",
            screens: [
                .feature: ScreenTemplate(
                    headline: TextSlot(y: 0.05, size: 0.08),
                    device: DeviceSlot(y: 0.36, width: 0.68)
                ),
            ]
        )
        let html = template.previewHTML
        // Light bg → dark text
        #expect(html.contains("#111111"))
    }

    @Test func `gallery template without device shows no wireframe phone`() {
        let template = GalleryTemplate(
            id: "hero-only",
            name: "Hero Only",
            background: "#000",
            screens: [
                .hero: ScreenTemplate(
                    headline: TextSlot(y: 0.25, size: 0.12)
                    // no device
                ),
            ]
        )
        let html = template.previewHTML
        #expect(html.contains("Hero Only"))
        #expect(!html.isEmpty)
    }

    @Test func `gallery template previewHTML is included in JSON encoding`() throws {
        let template = GalleryTemplate(
            id: "test",
            name: "Test",
            background: "#fff",
            screens: [
                .feature: ScreenTemplate(
                    headline: TextSlot(y: 0.05, size: 0.08),
                    device: DeviceSlot(y: 0.3, width: 0.7)
                ),
            ]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(template)
        let json = String(data: data, encoding: .utf8) ?? ""
        // previewHTML must be present in the encoded output
        #expect(json.contains("previewHTML"))
        #expect(json.contains("<!DOCTYPE html>"))
    }
}

import Foundation
import Testing
@testable import Domain

@Suite("TextSlot Preview")
struct TextSlotPreviewTests {

    @Test func `text slot has preview placeholder text`() {
        let slot = TextSlot(y: 0.03, size: 0.04, weight: 700, align: "left", preview: "APP MANAGEMENT")
        #expect(slot.preview == "APP MANAGEMENT")
    }

    @Test func `text slot preview defaults to nil`() {
        let slot = TextSlot(y: 0.04, size: 0.10)
        #expect(slot.preview == nil)
    }

    @Test func `screen template has tagline and subheading slots`() {
        let template = ScreenLayout(
            tagline: TextSlot(y: 0.03, size: 0.04, preview: "APP MANAGEMENT"),
            headline: TextSlot(y: 0.07, size: 0.085, preview: "Submit new\nversions in\nseconds."),
            subheading: TextSlot(y: 0.92, size: 0.055, preview: "Try it free →"),
            device: DeviceSlot(y: 0.28, width: 0.92)
        )
        #expect(template.tagline?.preview == "APP MANAGEMENT")
        #expect(template.headline.preview == "Submit new\nversions in\nseconds.")
        #expect(template.subheading?.preview == "Try it free →")
    }

    @Test func `screen template tagline and subheading are optional`() {
        let template = ScreenLayout(
            headline: TextSlot(y: 0.04, size: 0.10),
            device: DeviceSlot(y: 0.18, width: 0.85)
        )
        #expect(template.tagline == nil)
        #expect(template.subheading == nil)
    }

    @Test func `preview HTML uses TextSlot preview text when AppShot has no content`() {
        let template = ScreenLayout(
            tagline: TextSlot(y: 0.03, size: 0.04, preview: "SCREENSHOTS"),
            headline: TextSlot(y: 0.07, size: 0.085, preview: "Generate App\nStore shots"),
            device: DeviceSlot(y: 0.28, width: 0.85)
        )
        let palette = GalleryPalette(id: "t", name: "T", background: "#4338CA")
        let shot = AppShot(screenshot: "", type: .feature)
        // No headline set on shot — renderer uses TextSlot.preview
        let html = GalleryHTMLRenderer.renderScreen(shot, screenLayout: template, palette: palette)
        #expect(html.contains("SCREENSHOTS"))
        #expect(html.contains("Generate App"))
    }

    @Test func `render uses AppShot content over TextSlot preview`() {
        let template = ScreenLayout(
            tagline: TextSlot(y: 0.03, size: 0.04, preview: "DEFAULT TAGLINE"),
            headline: TextSlot(y: 0.07, size: 0.085, preview: "Default Headline")
        )
        let palette = GalleryPalette(id: "t", name: "T", background: "#000")
        let shot = AppShot(screenshot: "", type: .feature)
        shot.tagline = "MY TAGLINE"
        shot.headline = "My Real Headline"
        let html = GalleryHTMLRenderer.renderScreen(shot, screenLayout: template, palette: palette)
        #expect(html.contains("MY TAGLINE"))
        #expect(html.contains("My Real Headline"))
        #expect(!html.contains("DEFAULT TAGLINE"))
        #expect(!html.contains("Default Headline"))
    }

    @Test func `text slot with preview round-trips through JSON`() throws {
        let slot = TextSlot(y: 0.03, size: 0.04, weight: 700, align: "left", preview: "APP MANAGEMENT")
        let data = try JSONEncoder().encode(slot)
        let decoded = try JSONDecoder().decode(TextSlot.self, from: data)
        #expect(decoded.preview == "APP MANAGEMENT")
        #expect(decoded.y == 0.03)
    }
}

import Foundation
import Testing
@testable import Domain

@Suite("GalleryHTMLRenderer")
struct GalleryHTMLRendererTests {

    // MARK: - Helpers

    private let headlineSlot = TextSlot(y: 0.04, size: 0.10, weight: 900, align: "center")
    private let taglineSlot = TextSlot(y: 0.02, size: 0.03, weight: 600, align: "center", preview: "YOUR APP")
    private let subheadingSlot = TextSlot(y: 0.20, size: 0.035, weight: 400, align: "left")
    private let darkPalette = GalleryPalette(id: "p", name: "P", background: "#000")

    private func renderWithLayout(
        _ shot: AppShot,
        tagline: TextSlot? = nil,
        headline: TextSlot? = nil,
        subheading: TextSlot? = nil,
        device: DeviceSlot = DeviceSlot(y: 0.42, width: 0.85),
        decorations: [Decoration] = [],
        palette: GalleryPalette? = nil
    ) -> String {
        let layout = ScreenLayout(
            tagline: tagline,
            headline: headline ?? headlineSlot,
            subheading: subheading,
            device: device,
            decorations: decorations
        )
        return GalleryHTMLRenderer.renderScreen(shot, screenLayout: layout, palette: palette ?? darkPalette)
    }

    // MARK: - Headline

    @Test func `headline uses cqi font size`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Ship Faster"
        let html = renderWithLayout(shot)
        #expect(html.contains("10.0cqi"))
        #expect(html.contains("Ship Faster"))
    }

    @Test func `headline converts newlines to br`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Line 1\nLine 2"
        let html = renderWithLayout(shot)
        #expect(html.contains("Line 1<br>Line 2"))
    }

    // MARK: - Tagline

    @Test func `tagline uses cqi font size and uppercase`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        shot.tagline = "BEZELBLEND"
        let html = renderWithLayout(shot, tagline: taglineSlot)
        #expect(html.contains("3.0cqi"))
        #expect(html.contains("text-transform:uppercase"))
        #expect(html.contains("BEZELBLEND"))
    }

    // MARK: - Subheading

    @Test func `subheading uses cqi font size`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        shot.body = "Description text"
        let html = renderWithLayout(shot, subheading: subheadingSlot)
        #expect(html.contains("3.5cqi"))
        #expect(html.contains("Description text"))
    }

    // MARK: - Badges

    @Test func `badges use cqi font size`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        shot.badges = ["iPhone 17", "Mesh"]
        let html = renderWithLayout(shot)
        #expect(html.contains("2.8cqi"))
        #expect(html.contains("iPhone 17"))
        #expect(html.contains("Mesh"))
    }

    // MARK: - Trust Marks

    @Test func `trust marks render below headline`() {
        let shot = AppShot(screenshot: "", type: .hero)
        shot.headline = "Ship Faster"
        shot.trustMarks = ["4.9 STARS", "#1 IN CATEGORY"]
        let html = renderWithLayout(shot)
        #expect(html.contains("4.9 STARS"))
        #expect(html.contains("#1 IN CATEGORY"))
        #expect(html.contains("cqi"))
    }

    // MARK: - Device

    @Test func `device with screenshot produces img tag`() {
        let shot = AppShot(screenshot: "screen.png", type: .feature)
        shot.headline = "Test"
        let html = renderWithLayout(shot)
        #expect(html.contains("<img src=\"screen.png\""))
        #expect(html.contains("z-index:2"))
    }

    @Test func `device without screenshot produces wireframe`() {
        let shot = AppShot(screenshot: "", type: .feature)
        shot.headline = "Test"
        let html = renderWithLayout(shot)
        #expect(html.contains("9:41"))
    }

    // MARK: - Decorations

    @Test func `decorations render label with cqi units`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        let decos = [
            Decoration(shape: .label("✨"), x: 0.85, y: 0.12, size: 0.04, opacity: 0.6,
                       color: "#fff", background: "rgba(255,255,255,0.1)", borderRadius: "50%")
        ]
        let html = renderWithLayout(shot, decorations: decos)
        #expect(html.contains("✨"))
        #expect(html.contains("4.0cqi"))
        #expect(html.contains("left:85.0%"))
        #expect(html.contains("top:12.0%"))
        #expect(html.contains("z-index:3"))
    }

    @Test func `decorations with animation includes keyframes`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        let decos = [
            Decoration(shape: .label("⭐"), x: 0.5, y: 0.5, size: 0.04, animation: .float)
        ]
        let html = renderWithLayout(shot, decorations: decos)
        #expect(html.contains("@keyframes"))
        #expect(html.contains("td-float"))
    }

    // MARK: - Theme

    @Test func `screen uses data-theme attribute`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        let html = renderWithLayout(shot)
        #expect(html.contains("data-theme=\"dark\""))
    }

    @Test func `screen uses palette textColor when set`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        let palette = GalleryPalette(id: "p", name: "P", background: "#000", textColor: "#e0e7ff")
        let html = renderWithLayout(shot, palette: palette)
        #expect(html.contains("color:#e0e7ff"))
    }

    // MARK: - Full Render

    @Test func `screen output contains container-type inline-size`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        let html = renderWithLayout(shot)
        #expect(html.contains("container-type:inline-size"))
    }

    @Test func `all text elements use cqi sizing`() {
        let shot = AppShot(screenshot: "", type: .hero)
        shot.tagline = "TAG"
        shot.headline = "Head"
        shot.body = "Body"
        shot.badges = ["A"]
        shot.trustMarks = ["STARS"]
        let html = renderWithLayout(shot, tagline: taglineSlot, subheading: subheadingSlot)
        let fontSizes = html.components(separatedBy: "font-size:").dropFirst()
        for size in fontSizes {
            let value = String(size.prefix(while: { $0 != ";" && $0 != "\"" }))
            if !value.contains("max(") {
                #expect(value.hasSuffix("cqi"), "font-size '\(value)' does not use cqi units")
            }
        }
    }
}

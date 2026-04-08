import Foundation
import Testing
@testable import Domain

@Suite("GalleryHTMLRenderer")
struct GalleryHTMLRendererTests {

    // MARK: - Helpers

    private let headlineSlot = TextSlot(y: 0.04, size: 0.10, weight: 900, align: "center")
    private let taglineSlot = TextSlot(y: 0.02, size: 0.03, weight: 600, align: "center", preview: "YOUR APP")
    private let subheadingSlot = TextSlot(y: 0.20, size: 0.035, weight: 400, align: "left")

    // MARK: - Headline

    @Test func `renderHeadline uses cqi font size`() {
        let html = GalleryHTMLRenderer.renderHeadline(headlineSlot, content: "Ship Faster", isLight: false, pad: 5.0)
        #expect(html.contains("10.0cqi"))
        #expect(html.contains("Ship Faster"))
        #expect(html.contains("z-index:4"))
    }

    @Test func `renderHeadline converts newlines to br`() {
        let html = GalleryHTMLRenderer.renderHeadline(headlineSlot, content: "Line 1\nLine 2", isLight: false, pad: 5.0)
        #expect(html.contains("Line 1<br>Line 2"))
    }

    @Test func `renderHeadline returns empty for empty content`() {
        let html = GalleryHTMLRenderer.renderHeadline(headlineSlot, content: "", isLight: false, pad: 5.0)
        #expect(html.isEmpty)
    }

    // MARK: - Tagline

    @Test func `renderTagline uses cqi font size and uppercase`() {
        let html = GalleryHTMLRenderer.renderTagline(taglineSlot, content: "BEZELBLEND", isLight: false, pad: 5.0)
        #expect(html.contains("3.0cqi"))
        #expect(html.contains("text-transform:uppercase"))
        #expect(html.contains("BEZELBLEND"))
    }

    // MARK: - Subheading

    @Test func `renderSubheading uses cqi font size`() {
        let html = GalleryHTMLRenderer.renderSubheading(subheadingSlot, content: "Description text", isLight: false, pad: 5.0)
        #expect(html.contains("3.5cqi"))
        #expect(html.contains("Description text"))
    }

    // MARK: - Badges

    @Test func `renderBadges uses cqi font size at 0.28 ratio`() {
        let html = GalleryHTMLRenderer.renderBadges(["iPhone 17", "Mesh"], headlineSlot: headlineSlot, isLight: false)
        // headline size 0.10 * 100 * 0.28 = 2.8
        #expect(html.contains("2.8cqi"))
        #expect(html.contains("iPhone 17"))
        #expect(html.contains("Mesh"))
    }

    @Test func `renderBadges returns empty for no badges`() {
        let html = GalleryHTMLRenderer.renderBadges([], headlineSlot: headlineSlot, isLight: false)
        #expect(html.isEmpty)
    }

    // MARK: - Trust Marks

    @Test func `renderTrustMarks positions below headline`() {
        let html = GalleryHTMLRenderer.renderTrustMarks(
            ["4.9 STARS", "#1 IN CATEGORY"],
            headlineSlot: headlineSlot,
            headlineContent: "Ship Faster",
            isLight: false
        )
        #expect(html.contains("4.9 STARS"))
        #expect(html.contains("#1 IN CATEGORY"))
        #expect(html.contains("cqi"))
    }

    // MARK: - Device

    @Test func `renderDevice with screenshot produces img tag`() {
        let slot = DeviceSlot(x: 0.5, y: 0.42, width: 0.85)
        let html = GalleryHTMLRenderer.renderDevice(slot, screenshot: "screen.png", isLight: false)
        #expect(html.contains("<img src=\"screen.png\""))
        #expect(html.contains("z-index:2"))
    }

    @Test func `renderDevice without screenshot produces wireframe`() {
        let slot = DeviceSlot(x: 0.5, y: 0.42, width: 0.85)
        let html = GalleryHTMLRenderer.renderDevice(slot, screenshot: "", isLight: false)
        #expect(html.contains("9:41"))  // wireframe status bar
    }

    // MARK: - Decorations

    @Test func `renderDecorations renders label with cqi units`() {
        let decos = [
            Decoration(shape: .label("✨"), x: 0.85, y: 0.12, size: 0.04, opacity: 0.6,
                       color: "#fff", background: "rgba(255,255,255,0.1)", borderRadius: "50%")
        ]
        let html = GalleryHTMLRenderer.renderDecorations(decos, isLight: false)
        #expect(html.contains("✨"))
        #expect(html.contains("4.0cqi"))
        #expect(html.contains("left:85.0%"))
        #expect(html.contains("top:12.0%"))
        #expect(html.contains("z-index:3"))
    }

    @Test func `renderDecorations renders gem shape`() {
        let decos = [Decoration(shape: .gem, x: 0.9, y: 0.06, size: 0.06, opacity: 0.8)]
        let html = GalleryHTMLRenderer.renderDecorations(decos, isLight: false)
        #expect(html.contains("z-index:3"))
        #expect(html.contains("left:90.0%"))
        #expect(html.contains("cqi"))
    }

    @Test func `renderDecorations with animation includes keyframes`() {
        let decos = [
            Decoration(shape: .label("⭐"), x: 0.5, y: 0.5, size: 0.04, animation: .float)
        ]
        let html = GalleryHTMLRenderer.renderDecorations(decos, isLight: false)
        #expect(html.contains("@keyframes"))
        #expect(html.contains("td-float"))
    }

    @Test func `renderDecorations empty returns empty`() {
        let html = GalleryHTMLRenderer.renderDecorations([], isLight: false)
        #expect(html.isEmpty)
    }

    // MARK: - Palette textColor

    @Test func `renderScreen uses palette textColor when set`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        let layout = ScreenLayout(headline: headlineSlot, device: DeviceSlot(y: 0.42, width: 0.85))
        let palette = GalleryPalette(id: "p", name: "P", background: "#000", textColor: "#e0e7ff")
        let html = GalleryHTMLRenderer.renderScreen(shot, screenLayout: layout, palette: palette)
        #expect(html.contains("color:#e0e7ff"))
    }

    @Test func `renderScreen renders decorations from layout`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        let layout = ScreenLayout(
            headline: headlineSlot,
            device: DeviceSlot(y: 0.42, width: 0.85),
            decorations: [Decoration(shape: .label("🎯"), x: 0.1, y: 0.9, size: 0.03)]
        )
        let palette = GalleryPalette(id: "p", name: "P", background: "#000")
        let html = GalleryHTMLRenderer.renderScreen(shot, screenLayout: layout, palette: palette)
        #expect(html.contains("🎯"))
    }

    // MARK: - Full Render

    @Test func `renderScreen output contains container-type inline-size`() {
        let shot = AppShot(screenshot: "s.png", type: .feature)
        shot.headline = "Test"
        let layout = ScreenLayout(headline: headlineSlot, device: DeviceSlot(y: 0.42, width: 0.85))
        let palette = GalleryPalette(id: "p", name: "P", background: "#000")
        let html = GalleryHTMLRenderer.renderScreen(shot, screenLayout: layout, palette: palette)
        #expect(html.contains("container-type:inline-size"))
    }

    @Test func `all text elements use cqi sizing`() {
        let shot = AppShot(screenshot: "", type: .hero)
        shot.tagline = "TAG"
        shot.headline = "Head"
        shot.body = "Body"
        shot.badges = ["A"]
        shot.trustMarks = ["STARS"]
        let layout = ScreenLayout(
            tagline: taglineSlot,
            headline: headlineSlot,
            subheading: subheadingSlot,
            device: DeviceSlot(y: 0.5, width: 0.8)
        )
        let palette = GalleryPalette(id: "p", name: "P", background: "#000")
        let html = GalleryHTMLRenderer.renderScreen(shot, screenLayout: layout, palette: palette)
        // No px font sizes should appear for text elements
        // All font-size values should use cqi
        let fontSizes = html.components(separatedBy: "font-size:").dropFirst()
        for size in fontSizes {
            let value = String(size.prefix(while: { $0 != ";" && $0 != "\"" }))
            // All text font-sizes should end with cqi (wireframe uses max() which is ok)
            if !value.contains("max(") {
                #expect(value.hasSuffix("cqi"), "font-size '\(value)' does not use cqi units")
            }
        }
    }
}

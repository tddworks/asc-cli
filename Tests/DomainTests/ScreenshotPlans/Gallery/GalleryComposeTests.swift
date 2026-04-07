import Foundation
import Testing
@testable import Domain

@Suite("Gallery Compose")
struct GalleryComposeTests {

    // ── User: "I pick a template, my screenshots go in, I get HTML" ──

    @Test func `app shot composes with screen template and palette`() {
        let shot = AppShot(screenshot: "screen-0.png", type: .feature)
        shot.headline = "CUSTOMIZE EVERY DETAIL"

        let screenTemplate = ScreenTemplate(
            headline: TextSlot(y: 0.05, size: 0.08, weight: 900, align: "left"),
            device: DeviceSlot(y: 0.36, width: 0.68)
        )
        let palette = GalleryPalette(
            id: "green",
            name: "Green Mint",
            background: "linear-gradient(165deg, #a8ff78, #78ffd6)"
        )

        let html = shot.compose(screenTemplate: screenTemplate, palette: palette)
        #expect(html.contains("CUSTOMIZE EVERY DETAIL"))
        #expect(html.contains("9:41"))  // wireframe phone status bar
        #expect(html.contains("linear-gradient"))
    }

    @Test func `hero shot composes without device frame`() {
        let shot = AppShot(screenshot: "screen-0.png", type: .hero)
        shot.headline = "PREMIUM DEVICE MOCKUPS."

        let heroTemplate = ScreenTemplate(
            headline: TextSlot(y: 0.07, size: 0.08, weight: 900, align: "left")
            // no device — hero uses screenshot as background
        )
        let palette = GalleryPalette(
            id: "green",
            name: "Green",
            background: "linear-gradient(165deg, #a8ff78, #78ffd6)"
        )

        let html = shot.compose(screenTemplate: heroTemplate, palette: palette)
        #expect(html.contains("PREMIUM DEVICE MOCKUPS."))
        // hero has no device frame img tag
        #expect(!html.contains("<img"))
    }

    @Test func `feature shot composes with device frame`() {
        let shot = AppShot(screenshot: "screen-1.png", type: .feature)
        shot.headline = "Friends"

        let featureTemplate = ScreenTemplate(
            headline: TextSlot(y: 0.02, size: 0.10, weight: 900, align: "center"),
            device: DeviceSlot(y: 0.15, width: 0.85)
        )
        let palette = GalleryPalette(
            id: "blue",
            name: "Blue",
            background: "#edf1f8"
        )

        let html = shot.compose(screenTemplate: featureTemplate, palette: palette)
        #expect(html.contains("Friends"))
        #expect(html.contains("9:41"))  // wireframe phone
    }

    // ── User: "Gallery renders all my shots at once" ──

    @Test func `gallery renders all configured shots`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png", "screen-2.png"]
        )
        gallery.appShots[0].headline = "PREMIUM MOCKUPS"
        gallery.appShots[1].headline = "BACKGROUNDS"
        gallery.appShots[2].headline = "TEMPLATES"

        gallery.template = GalleryTemplate(
            id: "neon-pop",
            name: "Neon Pop",
            screens: [
                .hero: ScreenTemplate(headline: TextSlot(y: 0.07, size: 0.08)),
                .feature: ScreenTemplate(
                    headline: TextSlot(y: 0.05, size: 0.08),
                    device: DeviceSlot(y: 0.36, width: 0.68)
                ),
            ]
        )
        gallery.palette = GalleryPalette(
            id: "green",
            name: "Green",
            background: "linear-gradient(165deg, #a8ff78, #78ffd6)"
        )

        let results = gallery.renderAll()
        #expect(results.count == 3)
        #expect(results[0].contains("PREMIUM MOCKUPS"))
        #expect(results[1].contains("BACKGROUNDS"))
        #expect(results[2].contains("TEMPLATES"))
    }

    @Test func `gallery skips unconfigured shots`() {
        let gallery = Gallery(
            appName: "TestApp",
            screenshots: ["s0.png", "s1.png"]
        )
        gallery.appShots[0].headline = "Hero"
        // s1 has no headline — not configured

        gallery.template = GalleryTemplate(id: "t", name: "T", screens: [
            .hero: ScreenTemplate(headline: TextSlot(y: 0.05, size: 0.08)),
            .feature: ScreenTemplate(headline: TextSlot(y: 0.05, size: 0.08)),
        ])
        gallery.palette = GalleryPalette(id: "p", name: "P", background: "#fff")

        let results = gallery.renderAll()
        #expect(results.count == 1)
    }

    @Test func `gallery renderAll returns empty without template`() {
        let gallery = Gallery(appName: "X", screenshots: ["s.png"])
        gallery.appShots[0].headline = "H"
        gallery.palette = GalleryPalette(id: "p", name: "P", background: "#fff")

        #expect(gallery.renderAll().isEmpty)
    }

    @Test func `gallery renderAll returns empty without palette`() {
        let gallery = Gallery(appName: "X", screenshots: ["s.png"])
        gallery.appShots[0].headline = "H"
        gallery.template = GalleryTemplate(id: "t", name: "T", screens: [:])

        #expect(gallery.renderAll().isEmpty)
    }

    // ── User: "I can override template for a single shot" ──

    @Test func `single shot can use different template at render time`() {
        let shot = AppShot(screenshot: "screen-0.png")
        shot.headline = "Custom"

        let templateA = ScreenTemplate(
            headline: TextSlot(y: 0.02, size: 0.10, weight: 900, align: "center"),
            device: DeviceSlot(y: 0.15, width: 0.85)
        )
        let templateB = ScreenTemplate(
            headline: TextSlot(y: 0.25, size: 0.12, weight: 700, align: "left"),
            device: DeviceSlot(y: 0.30, width: 0.70)
        )
        let palette = GalleryPalette(id: "p", name: "P", background: "#000")

        let htmlA = shot.compose(screenTemplate: templateA, palette: palette)
        let htmlB = shot.compose(screenTemplate: templateB, palette: palette)

        // Same content, different layouts — both contain the headline
        #expect(htmlA.contains("Custom"))
        #expect(htmlB.contains("Custom"))
        // But different structure
        #expect(htmlA != htmlB)
    }
}

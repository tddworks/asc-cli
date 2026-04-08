import Foundation
import Testing
@testable import Domain

@Suite("Gallery Apply Screenshots")
struct GalleryApplyTests {

    // ── User: "I upload 5 screenshots with a gallery template" ──

    @Test func `gallery distributes screenshots to app shots by order`() {
        let gallery = Gallery(
            appName: "TestApp",
            screenshots: ["s0.png", "s1.png", "s2.png", "s3.png", "s4.png"]
        )
        #expect(gallery.appShots.count == 5)
        #expect(gallery.appShots[0].screenshot == "s0.png")
        #expect(gallery.appShots[0].type == .hero)
        #expect(gallery.appShots[1].screenshot == "s1.png")
        #expect(gallery.appShots[4].screenshot == "s4.png")
    }

    // ── User: "Single multi-device template consumes multiple screenshots" ──

    @Test func `side by side template creates fewer screens from same screenshots`() {
        let screenshots = ["s0.png", "s1.png", "s2.png", "s3.png", "s4.png"]

        // Single device template: 5 screenshots → 5 screens
        let singleDevice = ScreenLayout(
            headline: TextSlot(y: 0.04, size: 0.08),
            device: DeviceSlot(y: 0.18, width: 0.85)
        )
        let singleScreens = Gallery.distributeScreenshots(screenshots, screenLayout: singleDevice)
        #expect(singleScreens.count == 5)
        #expect(singleScreens[0] == ["s0.png"])
        #expect(singleScreens[4] == ["s4.png"])

        // Dual device template: 5 screenshots → 3 screens (2+2+1)
        let dualDevice = ScreenLayout(
            headline: TextSlot(y: 0.04, size: 0.08),
            devices: [
                DeviceSlot(x: 0.35, y: 0.20, width: 0.62),
                DeviceSlot(x: 0.65, y: 0.24, width: 0.62),
            ]
        )
        let dualScreens = Gallery.distributeScreenshots(screenshots, screenLayout: dualDevice)
        #expect(dualScreens.count == 3)
        #expect(dualScreens[0] == ["s0.png", "s1.png"])
        #expect(dualScreens[1] == ["s2.png", "s3.png"])
        #expect(dualScreens[2] == ["s4.png"])

        // Triple device template: 5 screenshots → 2 screens (3+2)
        let tripleDevice = ScreenLayout(
            headline: TextSlot(y: 0.04, size: 0.08),
            devices: [
                DeviceSlot(x: 0.22, y: 0.15, width: 0.45),
                DeviceSlot(x: 0.50, y: 0.12, width: 0.52),
                DeviceSlot(x: 0.78, y: 0.15, width: 0.45),
            ]
        )
        let tripleScreens = Gallery.distributeScreenshots(screenshots, screenLayout: tripleDevice)
        #expect(tripleScreens.count == 2)
        #expect(tripleScreens[0] == ["s0.png", "s1.png", "s2.png"])
        #expect(tripleScreens[1] == ["s3.png", "s4.png"])
    }

    // ── User: "AppShot can hold multiple screenshots for multi-device" ──

    @Test func `app shot can carry multiple screenshots`() {
        let shot = AppShot(screenshots: ["s0.png", "s1.png"], type: .feature)
        shot.headline = "Compare Plans"
        #expect(shot.screenshots == ["s0.png", "s1.png"])
        #expect(shot.screenshot == "s0.png")  // first one for backward compat
    }

    // ── User: "I apply my screenshots to a gallery template" ──

    @Test func `applyScreenshots creates new gallery with user screenshots and sample content`() {
        // Sample gallery (from gallery-templates.json)
        let sample = Gallery(appName: "BezelBlend", screenshots: ["", ""])
        sample.appShots[0].headline = "PREMIUM MOCKUPS"
        sample.appShots[0].tagline = "BEZELBLEND"
        sample.appShots[0].badges = ["iPhone 17"]
        sample.appShots[1].headline = "CUSTOMIZE"
        sample.appShots[1].tagline = "BACKGROUNDS"
        sample.template = GalleryTemplate(
            id: "neon-pop", name: "Neon Pop",
            background: "linear-gradient(165deg, #a8ff78, #78ffd6)",
            screens: [
                .hero: ScreenLayout(headline: TextSlot(y: 0.07, size: 0.08)),
                .feature: ScreenLayout(headline: TextSlot(y: 0.05, size: 0.08), device: DeviceSlot(y: 0.36, width: 0.68)),
            ]
        )
        sample.palette = GalleryPalette(id: "g", name: "G", background: "#a8ff78")

        // User applies their screenshots
        let gallery = sample.applyScreenshots(["my-hero.png", "my-feature.png"])

        // New gallery has user's screenshots
        #expect(gallery.appShots.count == 2)
        #expect(gallery.appShots[0].screenshot == "my-hero.png")
        #expect(gallery.appShots[1].screenshot == "my-feature.png")

        // But keeps sample content
        #expect(gallery.appShots[0].headline == "PREMIUM MOCKUPS")
        #expect(gallery.appShots[0].tagline == "BEZELBLEND")
        #expect(gallery.appShots[0].badges == ["iPhone 17"])
        #expect(gallery.appShots[1].headline == "CUSTOMIZE")

        // Keeps template and palette
        #expect(gallery.template?.id == "neon-pop")
        #expect(gallery.palette != nil)

        // Is ready to render
        #expect(gallery.isReady)
    }

    @Test func `applyScreenshots with more screenshots than sample creates extra feature shots`() {
        let sample = Gallery(appName: "App", screenshots: [""])
        sample.appShots[0].headline = "HERO"
        sample.template = GalleryTemplate(id: "t", name: "T", screens: [
            .hero: ScreenLayout(headline: TextSlot(y: 0.05, size: 0.08)),
            .feature: ScreenLayout(headline: TextSlot(y: 0.05, size: 0.08)),
        ])
        sample.palette = GalleryPalette(id: "p", name: "P", background: "#fff")

        let gallery = sample.applyScreenshots(["s0.png", "s1.png", "s2.png"])
        #expect(gallery.appShots.count == 3)
        #expect(gallery.appShots[0].headline == "HERO")
        #expect(gallery.appShots[0].type == .hero)
        #expect(gallery.appShots[1].type == .feature)
        #expect(gallery.appShots[2].type == .feature)
        // Extra shots beyond sample don't have headlines — not configured
        #expect(gallery.appShots[1].headline == nil)
    }
}

import Foundation
import Testing
@testable import Domain

@Suite("Gallery")
struct GalleryTests {

    // ── User: "I create a gallery from my screenshots" ──

    @Test func `gallery is created from screenshot files`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png", "screen-2.png"]
        )
        #expect(gallery.appName == "BezelBlend")
        #expect(gallery.shotCount == 3)
    }

    @Test func `first screenshot becomes hero, rest are features`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png", "screen-2.png"]
        )
        #expect(gallery.appShots[0].type == .hero)
        #expect(gallery.appShots[1].type == .feature)
        #expect(gallery.appShots[2].type == .feature)
    }

    @Test func `each app shot carries its screenshot`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png"]
        )
        #expect(gallery.appShots[0].screenshot == "screen-0.png")
        #expect(gallery.appShots[1].screenshot == "screen-1.png")
    }

    @Test func `hero shot is the first app shot`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png"]
        )
        #expect(gallery.heroShot?.screenshot == "screen-0.png")
        #expect(gallery.heroShot?.type == .hero)
    }

    // ── User: "I configure each shot with a headline" ──

    @Test func `new gallery has no configured shots`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png"]
        )
        #expect(gallery.unconfiguredShots.count == 2)
    }

    @Test func `configuring a shot reduces unconfigured count`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png"]
        )
        gallery.appShots[0].headline = "PREMIUM DEVICE MOCKUPS."
        #expect(gallery.unconfiguredShots.count == 1)
    }

    // ── User: "Is my gallery ready?" ──

    @Test func `gallery without template is not ready`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png"]
        )
        gallery.appShots[0].headline = "PREMIUM DEVICE MOCKUPS."
        #expect(!gallery.isReady)
    }

    @Test func `gallery without palette is not ready`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png"]
        )
        gallery.appShots[0].headline = "PREMIUM DEVICE MOCKUPS."
        gallery.template = GalleryTemplate(
            id: "walkthrough",
            name: "Feature Walkthrough",
            screens: [:]
        )
        #expect(!gallery.isReady)
    }

    @Test func `gallery with template and palette and all shots configured is ready`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png"]
        )
        gallery.appShots[0].headline = "PREMIUM DEVICE MOCKUPS."
        gallery.template = GalleryTemplate(
            id: "walkthrough",
            name: "Feature Walkthrough",
            screens: [:]
        )
        gallery.palette = GalleryPalette(
            id: "green-mint",
            name: "Green Mint",
            background: "linear-gradient(135deg, #c4f7a0, #a0f7e0)"
        )
        #expect(gallery.isReady)
    }

    @Test func `gallery with unconfigured shots is not ready`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png"]
        )
        gallery.appShots[0].headline = "PREMIUM DEVICE MOCKUPS."
        // screen-1 has no headline
        gallery.template = GalleryTemplate(
            id: "walkthrough",
            name: "Feature Walkthrough",
            screens: [:]
        )
        gallery.palette = GalleryPalette(
            id: "green-mint",
            name: "Green Mint",
            background: "linear-gradient(135deg, #c4f7a0, #a0f7e0)"
        )
        #expect(!gallery.isReady)
    }

    // ── User: "I can check my progress" ──

    @Test func `readiness shows progress`() {
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png", "screen-2.png"]
        )
        gallery.appShots[0].headline = "Hero"
        gallery.appShots[2].headline = "Feature 2"

        let readiness = gallery.readiness
        #expect(readiness.configuredCount == 2)
        #expect(readiness.totalCount == 3)
        #expect(!readiness.hasPalette)
        #expect(!readiness.hasTemplate)
        #expect(readiness.progress == "2/3 app shots configured")
    }
}

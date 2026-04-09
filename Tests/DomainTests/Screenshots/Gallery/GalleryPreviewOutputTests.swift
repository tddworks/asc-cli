import Foundation
import Testing
@testable import Domain

@Suite("Gallery Preview Output")
struct GalleryPreviewOutputTests {

    @Test func `gallery previewHTML renders all panels with correct content`() {
        let gallery = Gallery(appName: "TestApp", screenshots: ["s0.png", "s1.png", "s2.png"])
        gallery.appShots[0].headline = "PREMIUM\nMOCKUPS."
        gallery.appShots[0].tagline = "TESTAPP"
        gallery.appShots[0].badges = ["iPhone 17"]
        gallery.appShots[1].headline = "CUSTOMIZE"
        gallery.appShots[1].body = "Pick from solid colors"
        gallery.appShots[2].headline = "EXPORT"
        gallery.template = GalleryTemplate(
            id: "test-gallery", name: "Test Gallery",
            screens: [
                .hero: ScreenLayout(
                    tagline: TextSlot(y: 0.02, size: 0.03, weight: 600, align: "left", preview: "APP"),
                    headline: TextSlot(y: 0.07, size: 0.08, weight: 900, align: "left"),
                    device: DeviceSlot(x: 0.5, y: 0.35, width: 0.7)
                ),
                .feature: ScreenLayout(
                    headline: TextSlot(y: 0.05, size: 0.08, weight: 800, align: "center"),
                    subheading: TextSlot(y: 0.15, size: 0.035, weight: 400, align: "center"),
                    device: DeviceSlot(x: 0.5, y: 0.30, width: 0.68)
                ),
            ]
        )
        gallery.palette = GalleryPalette(
            id: "test", name: "Test", background: "linear-gradient(165deg, #a8ff78, #78ffd6)"
        )

        let html = gallery.previewHTML
        #expect(!html.isEmpty)
        #expect(html.contains("<!DOCTYPE html>"))
        // All panels should be present
        #expect(html.contains("PREMIUM"))
        #expect(html.contains("CUSTOMIZE"))
        #expect(html.contains("EXPORT"))
        // Gallery structure
        #expect(html.contains("#a8ff78"))
        #expect(html.contains("TESTAPP"))
    }

    @Test func `gallery previewHTML is empty when not ready`() {
        let gallery = Gallery(appName: "Test", screenshots: ["s0.png"])
        // No template or palette set
        let html = gallery.previewHTML
        #expect(html.isEmpty)
    }

    @Test func `gallery with dark palette uses dark theme`() {
        let gallery = Gallery(appName: "Test", screenshots: ["s0.png"])
        gallery.appShots[0].headline = "Dark"
        gallery.template = GalleryTemplate(id: "t", name: "T", screens: [
            .hero: ScreenLayout(headline: TextSlot(y: 0.04, size: 0.10)),
        ])
        gallery.palette = GalleryPalette(id: "p", name: "P", background: "#0a0a0a")
        let html = gallery.previewHTML
        #expect(html.contains("data-theme=\"dark\""))
    }
}

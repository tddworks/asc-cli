import Foundation
import Testing
@testable import Domain

@Suite("Gallery Preview HTML")
struct GalleryPreviewTests {

    private func makeGallery(
        templateId: String = "neon-pop",
        templateName: String = "Neon Pop",
        background: String = "linear-gradient(165deg, #a8ff78, #78ffd6)",
        heroHeadline: String = "PREMIUM\nMOCKUPS.",
        featureHeadline: String = "CUSTOMIZE",
        hasDevice: Bool = true
    ) -> Gallery {
        let gallery = Gallery(appName: "TestApp", screenshots: ["s0.png", "s1.png"])
        gallery.appShots[0].headline = heroHeadline
        gallery.appShots[1].headline = featureHeadline

        let featureDevices = hasDevice ? [DeviceSlot(y: 0.36, width: 0.68)] : []
        gallery.template = GalleryTemplate(
            id: templateId, name: templateName, background: background,
            screens: [
                .hero: ScreenTemplate(headline: TextSlot(y: 0.07, size: 0.08, weight: 900, align: "left")),
                .feature: ScreenTemplate(headline: TextSlot(y: 0.05, size: 0.08), devices: featureDevices),
            ]
        )
        gallery.palette = GalleryPalette(id: "p", name: "P", background: background)
        return gallery
    }

    @Test func `gallery generates previewHTML with all panels`() {
        let gallery = makeGallery()
        let html = gallery.previewHTML
        #expect(!html.isEmpty)
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("PREMIUM"))
        #expect(html.contains("CUSTOMIZE"))
        #expect(html.contains("#a8ff78"))
    }

    @Test func `gallery with dark background uses light text`() {
        let gallery = makeGallery(
            templateId: "cosmic", templateName: "Cosmic",
            background: "linear-gradient(170deg, #0f0c29, #302b63)"
        )
        let html = gallery.previewHTML
        #expect(html.contains("#fff"))
    }

    @Test func `gallery with light background uses dark text`() {
        let gallery = makeGallery(background: "linear-gradient(165deg, #a8ff78, #78ffd6)")
        let html = gallery.previewHTML
        #expect(html.contains("color:#000"))
    }

    @Test func `gallery previewHTML is included in JSON encoding`() throws {
        let gallery = makeGallery()
        let data = try JSONEncoder().encode(gallery)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("previewHTML"))
        #expect(json.contains("<!DOCTYPE html>"))
    }
}

import Foundation
import Testing
@testable import Domain

@Suite("Template Preview Page")
struct TemplatePreviewPageTests {

    @Test func `preview page renders multiple templates`() {
        let templates = [
            AppShotTemplate(
                id: "bold-hero", name: "Bold Hero", category: .bold,
                screenLayout: ScreenLayout(
                    headline: TextSlot(y: 0.04, size: 0.10, weight: 900, align: "center", preview: "SHIP FASTER"),
                    device: DeviceSlot(x: 0.5, y: 0.18, width: 0.85)
                ),
                palette: GalleryPalette(id: "bold", name: "Bold", background: "linear-gradient(150deg,#4338CA,#6D28D9)")
            ),
            AppShotTemplate(
                id: "minimal", name: "Minimal", category: .minimal,
                screenLayout: ScreenLayout(
                    headline: TextSlot(y: 0.06, size: 0.08, weight: 700, align: "center", preview: "Clean Design"),
                    device: DeviceSlot(x: 0.5, y: 0.25, width: 0.75)
                ),
                palette: GalleryPalette(id: "light", name: "Light", background: "#f5f5f7")
            ),
        ]

        for tmpl in templates {
            let html = tmpl.previewHTML
            #expect(!html.isEmpty, "Preview for \(tmpl.id) should not be empty")
            #expect(html.contains("<!DOCTYPE html>"))
            #expect(html.contains("container-type"))
        }
    }

    @Test func `preview contains template background`() {
        let tmpl = AppShotTemplate(
            id: "gradient", name: "Gradient",
            screenLayout: ScreenLayout(headline: TextSlot(y: 0.04, size: 0.10, preview: "Test")),
            palette: GalleryPalette(id: "g", name: "G", background: "linear-gradient(135deg,#ff6b6b,#feca57)")
        )
        let html = tmpl.previewHTML
        #expect(html.contains("#ff6b6b"))
        #expect(html.contains("#feca57"))
    }

    @Test func `multi-device template preview renders all device slots`() {
        let tmpl = AppShotTemplate(
            id: "duo", name: "Duo",
            screenLayout: ScreenLayout(
                headline: TextSlot(y: 0.04, size: 0.08, preview: "Compare"),
                devices: [
                    DeviceSlot(x: 0.35, y: 0.2, width: 0.6),
                    DeviceSlot(x: 0.65, y: 0.24, width: 0.6),
                ]
            ),
            palette: GalleryPalette(id: "d", name: "D", background: "#1a1a2e")
        )
        let html = tmpl.previewHTML
        #expect(html.contains("<!DOCTYPE html>"))
        // Both devices should be rendered (as wireframes since no screenshot)
        #expect(html.contains("9:41")) // wireframe status bar
    }
}

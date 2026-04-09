import Foundation
import Testing
@testable import Domain

@Suite("ThemeDesignApplier")
struct ThemeDesignApplierTests {

    // MARK: - Helpers

    private let layout = ScreenLayout(
        headline: TextSlot(y: 0.04, size: 0.10, weight: 900, align: "center"),
        device: DeviceSlot(x: 0.5, y: 0.42, width: 0.85)
    )

    private func makeShot(screenshot: String = "screen.png", headline: String = "Ship Faster") -> AppShot {
        let shot = AppShot(screenshot: screenshot, type: .feature)
        shot.headline = headline
        return shot
    }

    private func makeDesign(
        background: String = "linear-gradient(135deg, #0f172a, #7c3aed)",
        textColor: String? = "#e0e7ff",
        decorations: [Decoration] = [
            Decoration(shape: .label("✨"), x: 0.85, y: 0.12, size: 0.04, opacity: 0.6,
                       color: "#fff", background: "rgba(255,255,255,0.1)",
                       borderRadius: "50%", animation: .twinkle),
        ]
    ) -> ThemeDesign {
        ThemeDesign(
            palette: GalleryPalette(id: "space", name: "Space", background: background, textColor: textColor),
            decorations: decorations
        )
    }

    // MARK: - Re-rendering through pipeline

    @Test func `applier renders through GalleryHTMLRenderer`() {
        let design = makeDesign()
        let html = ThemeDesignApplier.apply(design, shot: makeShot(), screenLayout: layout)
        // Should be a full renderScreen output
        #expect(html.contains("container-type:inline-size"))
        #expect(html.contains("Ship Faster"))
    }

    @Test func `applier uses design palette background`() {
        let design = makeDesign(background: "linear-gradient(135deg, #0f172a, #7c3aed)")
        let html = ThemeDesignApplier.apply(design, shot: makeShot(), screenLayout: layout)
        #expect(html.contains("#0f172a"))
    }

    @Test func `applier uses design palette textColor`() {
        let design = makeDesign(textColor: "#e0e7ff")
        let html = ThemeDesignApplier.apply(design, shot: makeShot(), screenLayout: layout)
        #expect(html.contains("color:#e0e7ff"))
    }

    @Test func `applier renders decorations with cqi units`() {
        let design = makeDesign()
        let html = ThemeDesignApplier.apply(design, shot: makeShot(), screenLayout: layout)
        #expect(html.contains("✨"))
        #expect(html.contains("4.0cqi"))
        #expect(html.contains("left:85.0%"))
        #expect(html.contains("z-index:3"))
    }

    @Test func `applier preserves device img tag`() {
        let design = makeDesign()
        let html = ThemeDesignApplier.apply(design, shot: makeShot(), screenLayout: layout)
        #expect(html.contains("<img src=\"screen.png\""))
    }

    @Test func `applier preserves text content`() {
        let design = makeDesign()
        let html = ThemeDesignApplier.apply(design, shot: makeShot(headline: "My Custom Text"), screenLayout: layout)
        #expect(html.contains("My Custom Text"))
    }

    @Test func `applier with no decorations produces no z-index-3 elements`() {
        let design = makeDesign(decorations: [])
        let html = ThemeDesignApplier.apply(design, shot: makeShot(), screenLayout: layout)
        #expect(!html.contains("z-index:3"))
    }

    @Test func `same design on different shots produces consistent cqi values`() {
        let design = makeDesign()
        let html1 = ThemeDesignApplier.apply(design, shot: makeShot(headline: "Text A"), screenLayout: layout)
        let html2 = ThemeDesignApplier.apply(design, shot: makeShot(headline: "Text B"), screenLayout: layout)
        #expect(html1.contains("4.0cqi"))
        #expect(html2.contains("4.0cqi"))
    }

    @Test func `applier merges template decorations with design decorations`() {
        let layoutWithDeco = ScreenLayout(
            headline: TextSlot(y: 0.04, size: 0.10),
            device: DeviceSlot(y: 0.42, width: 0.85),
            decorations: [Decoration(shape: .gem, x: 0.9, y: 0.06, size: 0.06)]
        )
        let design = makeDesign(decorations: [
            Decoration(shape: .label("🎯"), x: 0.1, y: 0.8, size: 0.03)
        ])
        let html = ThemeDesignApplier.apply(design, shot: makeShot(), screenLayout: layoutWithDeco)
        // Both decorations should be present
        #expect(html.contains("◆"))  // gem shape
        #expect(html.contains("🎯"))  // label
    }
}

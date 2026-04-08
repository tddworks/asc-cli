import Foundation
import Testing
@testable import Domain

@Suite("ScreenTemplate")
struct ScreenTemplateGalleryTests {

    // ── User: "My gallery template has different layouts per screen type" ──

    @Test func `gallery template maps screen types to screen templates`() {
        let heroLayout = ScreenTemplate(
            headline: TextSlot(y: 0.25, size: 0.12, weight: 900, align: "left")
        )
        let featureLayout = ScreenTemplate(
            headline: TextSlot(y: 0.02, size: 0.10, weight: 900, align: "center"),
            device: DeviceSlot(y: 0.15, width: 0.85)
        )
        let template = GalleryTemplate(
            id: "walkthrough",
            name: "Feature Walkthrough",
            screens: [.hero: heroLayout, .feature: featureLayout]
        )
        #expect(template.screens[.hero] != nil)
        #expect(template.screens[.feature] != nil)
        #expect(template.screens[.social] == nil)
    }

    // ── User: "Hero has no device frame — screenshot IS the background" ──

    @Test func `hero screen template has no device slot`() {
        let hero = ScreenTemplate(
            headline: TextSlot(y: 0.25, size: 0.12)
        )
        #expect(hero.devices.isEmpty)
    }

    // ── User: "Feature screen has a device frame" ──

    @Test func `feature screen template has device slot`() {
        let feature = ScreenTemplate(
            headline: TextSlot(y: 0.02, size: 0.10),
            device: DeviceSlot(y: 0.15, width: 0.85)
        )
        #expect(feature.devices.count == 1)
        #expect(feature.devices.first?.width == 0.85)
    }

    // ── User: "Templates can have decorative shapes" ──

    @Test func `screen template can have decorations`() {
        let feature = ScreenTemplate(
            headline: TextSlot(y: 0.02, size: 0.10),
            device: DeviceSlot(y: 0.15, width: 0.85),
            decorations: [
                Decoration(shape: .gem, x: 0.85, y: 0.1, size: 0.04),
                Decoration(shape: .orb, x: 0.1, y: 0.9, size: 0.03, opacity: 0.6),
            ]
        )
        #expect(feature.decorations.count == 2)
        #expect(feature.decorations[0].shape == .gem)
        #expect(feature.decorations[1].opacity == 0.6)
    }

    @Test func `screen template defaults to no decorations`() {
        let feature = ScreenTemplate(
            headline: TextSlot(y: 0.02, size: 0.10)
        )
        #expect(feature.decorations.isEmpty)
    }
}

@Suite("GalleryPalette")
struct GalleryPaletteTests {

    // ── User: "I pick a color scheme for my gallery" ──

    @Test func `palette has id, name, and background`() {
        let palette = GalleryPalette(
            id: "green-mint",
            name: "Green Mint",
            background: "linear-gradient(135deg, #c4f7a0, #a0f7e0)"
        )
        #expect(palette.id == "green-mint")
        #expect(palette.name == "Green Mint")
        #expect(palette.background.contains("gradient"))
    }
}

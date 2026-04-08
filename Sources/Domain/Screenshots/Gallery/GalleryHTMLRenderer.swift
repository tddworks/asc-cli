import Foundation

/// Renders App Store screenshot screens as HTML.
///
/// **SRP:** Builds context dictionaries from domain models. Nothing else.
/// **OCP:** All HTML, CSS colors, keyframes, and theme logic live in templates.
///
/// One entry point: `renderScreen()` → `buildScreenContext()` → `screen.html`.
public enum GalleryHTMLRenderer {

    /// The template repository. Plugins can replace to provide custom templates.
    nonisolated(unsafe) public static var templateRepository: any HTMLTemplateRepository = BundledHTMLTemplateRepository()

    nonisolated(unsafe) public static var phoneFrameDataURL: String?

    // MARK: - Screen Rendering

    /// Render a single AppShot as an HTML fragment for one screen.
    public static func renderScreen(
        _ shot: AppShot,
        screenLayout: ScreenLayout,
        palette: GalleryPalette
    ) -> String {
        let context = buildScreenContext(shot, screenLayout: screenLayout, palette: palette)
        return HTMLComposer.render(loadTemplate("screen"), with: context)
    }

    /// Build the full context dictionary for a screen template.
    public static func buildScreenContext(
        _ shot: AppShot,
        screenLayout: ScreenLayout,
        palette: GalleryPalette
    ) -> [String: Any] {
        let hl = screenLayout.headline
        let pad = 5.0

        var context: [String: Any] = [
            "background": palette.background,
            "theme": palette.isLight ? "light" : "dark",
            "themeVars": loadTemplate("theme-vars"),
        ]

        // Tagline
        if let tgSlot = screenLayout.tagline {
            let tgText = shot.tagline ?? tgSlot.preview ?? ""
            if !tgText.isEmpty {
                context["tagline"] = textSlotContext(tgSlot, content: tgText, color: palette.headlineColor, pad: pad)
            }
        }

        // Headline
        let hlContent = shot.headline ?? hl.preview ?? ""
        if !hlContent.isEmpty {
            context["headline"] = textSlotContext(hl, content: hlContent.replacingOccurrences(of: "\n", with: "<br>"), color: palette.headlineColor, pad: pad)
        }

        // Subheading
        if let subSlot = screenLayout.subheading {
            let subText = shot.body ?? subSlot.preview ?? ""
            if !subText.isEmpty {
                var sub = textSlotContext(subSlot, content: subText.replacingOccurrences(of: "\n", with: "<br>"), color: "", pad: pad)
                sub["padRight"] = fmt(pad + 3)
                context["subheading"] = sub
            }
        }

        // Trust marks
        if let marks = shot.trustMarks, !marks.isEmpty {
            let hlLines = Double(hlContent.components(separatedBy: "\n").count)
            let afterHeading = hl.y * 100 + hlLines * hl.size * 100 * 1.0 + 1
            context["trustMarksHTML"] = "1"
            context["trustMarks"] = [
                "top": fmt(afterHeading),
                "pad": fmt(pad),
                "items": marks.map { ["text": $0, "fontSize": fmt(hl.size * 100 * 0.28)] },
            ] as [String: Any]
        }

        // Badges
        if !shot.badges.isEmpty {
            context["badges"] = badgeContexts(shot.badges, headlineSlot: hl)
        }

        // Devices
        let devSlots = screenLayout.devices.isEmpty && shot.type == .hero
            ? [DeviceSlot(x: 0.5, y: 0.42, width: 0.65)]
            : screenLayout.devices
        context["devices"] = devSlots.enumerated().map { (devIndex, dev) in
            let screenshotFile = devIndex < shot.screenshots.count ? shot.screenshots[devIndex] : ""
            return deviceContext(dev, screenshot: screenshotFile)
        }

        // Decorations
        if !screenLayout.decorations.isEmpty {
            context["decorations"] = decorationContexts(screenLayout.decorations)
            if screenLayout.decorations.contains(where: { $0.animation != nil }) {
                context["hasAnimations"] = "1"
                context["keyframesHTML"] = loadTemplate("keyframes")
            }
        }

        return context
    }

    // MARK: - Page Wrapper

    public static func wrapPage(_ inner: String, fillViewport: Bool = false) -> String {
        HTMLComposer.render(loadTemplate("page-wrapper"), with: pageContext(inner: inner, fillViewport: fillViewport))
    }

    /// Build page wrapper context. Shared with `ThemedPage`.
    public static func pageContext(
        inner: String,
        fillViewport: Bool = false,
        width: Int = 1320,
        height: Int = 2868
    ) -> [String: Any] {
        var ctx: [String: Any] = [
            "inner": inner,
            "aspectRatio": "\(width)/\(height)",
        ]
        if fillViewport { ctx["fillViewport"] = "1" }
        return ctx
    }

    // MARK: - Preview

    public static func renderPreviewPage(_ gallery: Gallery) -> String {
        let screens = gallery.renderAll()
        guard !screens.isEmpty else { return "" }
        let screenTemplate = loadTemplate("preview-screen")
        let screenDivs = screens.map { HTMLComposer.render(screenTemplate, with: ["screen": $0]) }.joined()
        return HTMLComposer.render(loadTemplate("preview-page"), with: [
            "screenDivs": screenDivs,
            "themeVars": loadTemplate("theme-vars"),
        ])
    }

    // MARK: - Context Builders (pure data mapping)

    private static func textSlotContext(_ slot: TextSlot, content: String, color: String, pad: Double) -> [String: Any] {
        [
            "top": fmt(slot.y * 100), "pad": fmt(pad),
            "weight": "\(slot.weight)", "fontSize": fmt(slot.size * 100),
            "color": color, "align": slot.align, "content": content,
        ]
    }

    private static func badgeContexts(_ badges: [String], headlineSlot hl: TextSlot) -> [[String: Any]] {
        let badgeTop = hl.y * 100 + 1.0
        return badges.enumerated().map { (i, badge) in
            let bx = hl.align == "left" ? 65.0 + Double(i % 2) * 12.0 : 60.0 + Double(i % 2) * 15.0
            return [
                "left": fmt(bx), "top": fmt(badgeTop + Double(i) * 7.0),
                "fontSize": fmt(hl.size * 100 * 0.28), "text": badge,
            ]
        }
    }

    private static func decorationContexts(_ decorations: [Decoration]) -> [[String: Any]] {
        decorations.enumerated().map { (i, deco) in
            [
                "left": fmt(deco.x * 100), "top": fmt(deco.y * 100),
                "fontSize": fmt(deco.size * 100), "opacity": fmt(deco.opacity),
                "background": deco.background ?? "transparent",
                "color": deco.color ?? "",
                "useDefaultColor": deco.color == nil ? "1" : "",
                "borderRadius": deco.borderRadius ?? "50%",
                "animStyle": deco.animation.map { "animation:td-\($0.rawValue) \(3 + i % 4)s ease-in-out infinite;" } ?? "",
                "content": deco.shape.displayCharacter,
            ]
        }
    }

    private static func deviceContext(_ slot: DeviceSlot, screenshot: String) -> [String: Any] {
        let dl = fmt((slot.x - slot.width / 2) * 100)
        let dt = fmt(slot.y * 100)
        let dw = fmt(slot.width * 100)

        if !screenshot.isEmpty {
            return ["left": dl, "top": dt, "width": dw, "hasScreenshot": "1", "screenshot": screenshot]
        } else {
            var ctx: [String: Any] = ["left": dl, "top": dt, "width": dw, "hasWireframe": "1"]
            ctx["wireframeHTML"] = loadTemplate("wireframe")
            if let dataURL = phoneFrameDataURL {
                ctx["hasPhoneFrame"] = "1"
                ctx["phoneFrameURL"] = dataURL
            } else {
                ctx["noPhoneFrame"] = "1"
            }
            return ctx
        }
    }

    // MARK: - Helpers

    static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    static func loadTemplate(_ name: String) -> String {
        templateRepository.template(named: name) ?? ""
    }
}

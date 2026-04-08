import Foundation

/// Renders App Store screenshot screens as HTML.
///
/// Uses `cqi` units + `container-type:inline-size` for responsive scaling.
/// Screen aspect ratio: 1320/2868 (iPhone App Store screenshot).
///
/// **OCP:** All HTML lives in external template files loaded via `HTMLTemplateRepository`.
/// To change the visual output, swap templates — don't modify this code.
/// This renderer only prepares data contexts and delegates to templates.
public enum GalleryHTMLRenderer {

    /// The template repository used to load HTML templates.
    /// Defaults to `BundledHTMLTemplateRepository` which reads from bundle resources.
    /// Plugins can replace this to provide custom templates.
    nonisolated(unsafe) public static var templateRepository: any HTMLTemplateRepository = BundledHTMLTemplateRepository()

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
        let bg = palette.background
        let hl = screenLayout.headline
        let isLight = palette.textColor == nil ? isLightBackground(bg) : false
        let headlineColor = palette.textColor ?? (isLight ? "#000" : "#fff")
        let pad = 5.0

        var context: [String: Any] = ["background": bg]

        // Tagline
        if let tgSlot = screenLayout.tagline {
            let tgText = shot.tagline ?? tgSlot.preview ?? ""
            if !tgText.isEmpty {
                context["tagline"] = textSlotContext(tgSlot, content: tgText, color: headlineColor, pad: pad)
            }
        }

        // Headline
        let hlContent = shot.headline ?? hl.preview ?? ""
        if !hlContent.isEmpty {
            context["headline"] = textSlotContext(hl, content: hlContent.replacingOccurrences(of: "\n", with: "<br>"), color: headlineColor, pad: pad)
        }

        // Subheading
        if let subSlot = screenLayout.subheading {
            let subText = shot.body ?? subSlot.preview ?? ""
            if !subText.isEmpty {
                let bodyColor = isLight ? "#1a1a1a" : "rgba(255,255,255,0.7)"
                var sub = textSlotContext(subSlot, content: subText.replacingOccurrences(of: "\n", with: "<br>"), color: bodyColor, pad: pad)
                sub["padRight"] = fmt(pad + 3)
                context["subheading"] = sub
            }
        }

        // Trust marks
        if let marks = shot.trustMarks, !marks.isEmpty {
            let badgeBg = isLight ? "rgba(0,0,0,0.07)" : "rgba(255,255,255,0.12)"
            let trustColor = isLight ? "rgba(0,0,0,0.55)" : "rgba(255,255,255,0.6)"
            let hlLines = Double(hlContent.components(separatedBy: "\n").count)
            let afterHeading = hl.y * 100 + hlLines * hl.size * 100 * 1.0 + 1
            let markSize = fmt(hl.size * 100 * 0.28)
            context["trustMarksHTML"] = "1"
            context["trustMarks"] = [
                "top": fmt(afterHeading),
                "pad": fmt(pad),
                "items": marks.map { ["text": $0, "badgeBg": badgeBg, "fontSize": markSize, "color": trustColor] },
            ] as [String: Any]
        }

        // Badges
        if !shot.badges.isEmpty {
            context["badges"] = badgeContexts(shot.badges, headlineSlot: hl, isLight: isLight)
        }

        // Devices
        let devSlots = screenLayout.devices.isEmpty && shot.type == .hero
            ? [DeviceSlot(x: 0.5, y: 0.42, width: 0.65)]
            : screenLayout.devices
        context["devices"] = devSlots.enumerated().map { (devIndex, dev) in
            let screenshotFile = devIndex < shot.screenshots.count ? shot.screenshots[devIndex] : ""
            return buildDeviceContext(dev, screenshot: screenshotFile, isLight: isLight)
        }

        // Decorations
        if !screenLayout.decorations.isEmpty {
            let defaultColor = isLight ? "rgba(0,0,0,0.25)" : "rgba(255,255,255,0.25)"
            context["decorations"] = decorationContexts(screenLayout.decorations, defaultColor: defaultColor)
            let animations = Set(screenLayout.decorations.compactMap(\.animation))
            if !animations.isEmpty {
                context["keyframeStyles"] = animations.sorted(by: { $0.rawValue < $1.rawValue })
                    .map { keyframeCSS(for: $0) }.joined()
            }
        }

        return context
    }

    // MARK: - Text Elements

    /// Render a tagline (small caps text above headline).
    public static func renderTagline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let color = headlineColor ?? (isLight ? "rgba(0,0,0,0.40)" : "rgba(255,255,255,0.45)")
        return HTMLComposer.render(loadTemplate("tagline"), with: textSlotContext(slot, content: content, color: color, pad: pad))
    }

    /// Render the headline text.
    public static func renderHeadline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let color = headlineColor ?? (isLight ? "#000" : "#fff")
        let hlText = content.replacingOccurrences(of: "\n", with: "<br>")
        return HTMLComposer.render(loadTemplate("headline"), with: textSlotContext(slot, content: hlText, color: color, pad: pad))
    }

    /// Render subheading text below headline.
    public static func renderSubheading(_ slot: TextSlot, content: String, isLight: Bool, pad: Double) -> String {
        guard !content.isEmpty else { return "" }
        let bodyColor = isLight ? "#1a1a1a" : "rgba(255,255,255,0.7)"
        let subContent = content.replacingOccurrences(of: "\n", with: "<br>")
        var ctx = textSlotContext(slot, content: subContent, color: bodyColor, pad: pad)
        ctx["padRight"] = fmt(pad + 3)
        return HTMLComposer.render(loadTemplate("subheading"), with: ctx)
    }

    // MARK: - Badges & Trust Marks

    /// Render floating badge pills.
    public static func renderBadges(_ badges: [String], headlineSlot hl: TextSlot, isLight: Bool) -> String {
        guard !badges.isEmpty else { return "" }
        let template = loadTemplate("badge")
        return badgeContexts(badges, headlineSlot: hl, isLight: isLight)
            .map { HTMLComposer.render(template, with: $0) }
            .joined()
    }

    /// Render trust marks positioned below headline.
    public static func renderTrustMarks(_ marks: [String], headlineSlot hl: TextSlot, headlineContent: String, isLight: Bool) -> String {
        guard !marks.isEmpty else { return "" }
        let badgeBg = isLight ? "rgba(0,0,0,0.07)" : "rgba(255,255,255,0.12)"
        let trustColor = isLight ? "rgba(0,0,0,0.55)" : "rgba(255,255,255,0.6)"
        let pad = 5.0
        let hlLines = Double(headlineContent.components(separatedBy: "\n").count)
        let afterHeading = hl.y * 100 + hlLines * hl.size * 100 * 1.0 + 1
        let markSize = fmt(hl.size * 100 * 0.28)
        let markTemplate = loadTemplate("trust-mark")
        let items = marks.map { mark in
            HTMLComposer.render(markTemplate, with: ["text": mark, "badgeBg": badgeBg, "fontSize": markSize, "color": trustColor])
        }.joined()
        return HTMLComposer.render(loadTemplate("trust-marks-wrapper"), with: [
            "top": fmt(afterHeading), "pad": fmt(pad), "items": items,
        ])
    }

    // MARK: - Device

    /// Render a device frame — real screenshot or wireframe.
    public static func renderDevice(_ slot: DeviceSlot, screenshot: String, isLight: Bool) -> String {
        let ctx = buildDeviceContext(slot, screenshot: screenshot, isLight: isLight)
        if !screenshot.isEmpty {
            return HTMLComposer.render(loadTemplate("device-screenshot"), with: ctx)
        } else {
            return HTMLComposer.render(loadTemplate("device-wireframe"), with: ctx)
        }
    }

    /// Render decorations.
    public static func renderDecorations(_ decorations: [Decoration], isLight: Bool) -> String {
        guard !decorations.isEmpty else { return "" }
        let defaultColor = isLight ? "rgba(0,0,0,0.25)" : "rgba(255,255,255,0.25)"
        let template = loadTemplate("decoration")
        var html = decorationContexts(decorations, defaultColor: defaultColor)
            .map { HTMLComposer.render(template, with: $0) }
            .joined()
        let animations = Set(decorations.compactMap(\.animation))
        if !animations.isEmpty {
            let keyframes = animations.sorted(by: { $0.rawValue < $1.rawValue })
                .map { keyframeCSS(for: $0) }.joined()
            html += HTMLComposer.render(loadTemplate("keyframes"), with: ["keyframes": keyframes])
        }
        return html
    }

    // MARK: - Page Wrapper

    /// Wrap a rendered screen fragment in a full HTML page.
    public static func wrapPage(_ inner: String, fillViewport: Bool = false) -> String {
        let styles = buildPageStyles(fillViewport: fillViewport)
        return HTMLComposer.render(loadTemplate("page-wrapper"), with: ["styles": styles, "inner": inner])
    }

    /// Build the full CSS string for page-wrapper.
    /// CSS construction stays in Swift because CSS `{` braces conflict with `{{` template syntax.
    public static func buildPageStyles(
        fillViewport: Bool = false,
        width: Int = 1320,
        height: Int = 2868
    ) -> String {
        let previewStyle = fillViewport
            ? "width:100%;height:100%;container-type:inline-size"
            : "width:320px;aspect-ratio:\(width)/\(height);container-type:inline-size"
        let bodyStyle = fillViewport
            ? "margin:0;overflow:hidden"
            : "display:flex;justify-content:center;align-items:center;min-height:100vh;background:#111"
        let htmlHeight = fillViewport ? "html,body{width:100%;height:100%}" : ""
        return "*{margin:0;padding:0;box-sizing:border-box}\(htmlHeight)body{\(bodyStyle)}.preview{\(previewStyle)}"
    }

    /// Load the page-wrapper template. Shared by `wrapPage()` and `ThemedPage`.
    public static func loadPageWrapperTemplate() -> String {
        loadTemplate("page-wrapper")
    }

    // MARK: - Preview

    /// Render a gallery preview page — multiple screens in a horizontal strip.
    public static func renderPreviewPage(_ gallery: Gallery) -> String {
        let screens = gallery.renderAll()
        guard !screens.isEmpty else { return "" }
        let screenTemplate = loadTemplate("preview-screen")
        let screenDivs = screens.map { HTMLComposer.render(screenTemplate, with: ["screen": $0]) }.joined()
        return HTMLComposer.render(loadTemplate("preview-page"), with: ["screenDivs": screenDivs])
    }

    // MARK: - Context Builders

    private static func textSlotContext(_ slot: TextSlot, content: String, color: String, pad: Double) -> [String: Any] {
        [
            "top": fmt(slot.y * 100),
            "pad": fmt(pad),
            "weight": "\(slot.weight)",
            "fontSize": fmt(slot.size * 100),
            "color": color,
            "align": slot.align,
            "content": content,
        ]
    }

    private static func badgeContexts(_ badges: [String], headlineSlot hl: TextSlot, isLight: Bool) -> [[String: Any]] {
        let badgeBg = isLight ? "rgba(0,0,0,0.07)" : "rgba(255,255,255,0.12)"
        let badgeColor = isLight ? "#1a1a1a" : "#fff"
        let badgeBorder = isLight ? "rgba(0,0,0,0.08)" : "rgba(255,255,255,0.15)"
        let badgeTop = hl.y * 100 + 1.0
        return badges.enumerated().map { (i, badge) in
            let bx = hl.align == "left" ? 65.0 + Double(i % 2) * 12.0 : 60.0 + Double(i % 2) * 15.0
            let by = badgeTop + Double(i) * 7.0
            return [
                "left": fmt(bx), "top": fmt(by),
                "badgeBg": badgeBg, "badgeBorder": badgeBorder,
                "fontSize": fmt(hl.size * 100 * 0.28),
                "color": badgeColor, "text": badge,
            ]
        }
    }

    private static func decorationContexts(_ decorations: [Decoration], defaultColor: String) -> [[String: Any]] {
        decorations.enumerated().map { (i, deco) in
            [
                "left": fmt(deco.x * 100),
                "top": fmt(deco.y * 100),
                "fontSize": fmt(deco.size * 100),
                "opacity": fmt(deco.opacity),
                "background": deco.background ?? "transparent",
                "color": deco.color ?? defaultColor,
                "borderRadius": deco.borderRadius ?? "50%",
                "animStyle": deco.animation.map { "animation:td-\($0.rawValue) \(3 + i % 4)s ease-in-out infinite;" } ?? "",
                "content": shapeContent(deco.shape),
            ]
        }
    }

    private static func buildDeviceContext(_ slot: DeviceSlot, screenshot: String, isLight: Bool) -> [String: Any] {
        let dl = fmt((slot.x - slot.width / 2) * 100)
        let dt = fmt(slot.y * 100)
        let dw = fmt(slot.width * 100)

        if !screenshot.isEmpty {
            return ["left": dl, "top": dt, "width": dw, "hasScreenshot": "1", "screenshot": screenshot]
        } else {
            let shadow = isLight ? "0.12" : "0.35"
            let frameBg = isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.08)"
            let frameBorder = isLight ? "rgba(0,0,0,0.12)" : "rgba(255,255,255,0.15)"

            let outerStyle: String
            let frameOverlay: String
            if let dataURL = phoneFrameDataURL {
                frameOverlay = HTMLComposer.render(loadTemplate("frame-overlay"), with: ["dataURL": dataURL])
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)))"
            } else {
                frameOverlay = ""
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)));background:\(frameBg);border-radius:12%/5.5%;border:1.5px solid \(frameBorder);overflow:hidden"
            }

            let wireframeHTML = HTMLComposer.render(loadTemplate("wireframe"), with: wireframeContext(isLight: isLight))
            return [
                "left": dl, "top": dt, "width": dw,
                "hasWireframe": "1",
                "outerStyle": outerStyle,
                "wireframeHTML": wireframeHTML,
                "frameOverlay": frameOverlay,
            ]
        }
    }

    private static func wireframeContext(isLight: Bool) -> [String: Any] {
        [
            "scr": isLight ? "rgba(255,255,255,0.65)" : "rgba(255,255,255,0.06)",
            "ui": isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.06)",
            "ui2": isLight ? "rgba(0,0,0,0.10)" : "rgba(255,255,255,0.09)",
            "uitx": isLight ? "rgba(0,0,0,0.30)" : "rgba(255,255,255,0.25)",
        ]
    }

    // MARK: - Internal Helpers

    static func isLightBackground(_ bg: String) -> Bool {
        let lightHex = ["#f", "#F", "#e", "#E", "#d", "#D", "#c", "#C", "#b", "#B", "#a8", "#A8", "#9"]
        return lightHex.contains(where: { bg.contains($0) })
    }

    nonisolated(unsafe) public static var phoneFrameDataURL: String?

    static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private static func shapeContent(_ shape: DecorationShape) -> String {
        switch shape {
        case .label(let text): return text
        case .gem: return "◆"
        case .orb: return "●"
        case .sparkle: return "✦"
        case .arrow: return "›"
        }
    }

    private static func keyframeCSS(for animation: DecorationAnimation) -> String {
        switch animation {
        case .float:
            return "@keyframes td-float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}"
        case .drift:
            return "@keyframes td-drift{0%,100%{transform:translate(0,0)}50%{transform:translate(5px,-5px)}}"
        case .pulse:
            return "@keyframes td-pulse{0%,100%{transform:scale(1)}50%{transform:scale(1.15)}}"
        case .spin:
            return "@keyframes td-spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}"
        case .twinkle:
            return "@keyframes td-twinkle{0%,100%{opacity:0.5}50%{opacity:0.8}}"
        }
    }

    /// Load an HTML template by name, falling back to empty string.
    static func loadTemplate(_ name: String) -> String {
        templateRepository.template(named: name) ?? ""
    }
}

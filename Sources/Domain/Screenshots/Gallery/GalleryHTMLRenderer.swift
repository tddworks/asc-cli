import Foundation

/// Renders App Store screenshot screens as HTML.
///
/// Uses `cqi` units + `container-type:inline-size` for responsive scaling.
/// Screen aspect ratio: 1320/2868 (iPhone App Store screenshot).
///
/// HTML structure is loaded from external template files via `HTMLTemplateRepository`.
/// Set `templateRepository` to override the built-in templates.
public enum GalleryHTMLRenderer {

    /// The template repository used to load HTML templates.
    /// Defaults to `BundledHTMLTemplateRepository` which reads from bundle resources.
    /// Plugins can replace this to provide custom templates.
    nonisolated(unsafe) public static var templateRepository: any HTMLTemplateRepository = BundledHTMLTemplateRepository()

    /// Render a single AppShot as an HTML fragment for one screen.
    public static func renderScreen(
        _ shot: AppShot,
        screenLayout: ScreenLayout,
        palette: GalleryPalette
    ) -> String {
        let bg = palette.background
        let hl = screenLayout.headline
        let isLight = palette.textColor == nil ? isLightBackground(bg) : false
        let headlineColor = palette.textColor ?? (isLight ? "#000" : "#fff")
        let pad = 5.0

        var textHTML = ""

        // Tagline
        if let tgSlot = screenLayout.tagline {
            let tgText = shot.tagline ?? tgSlot.preview ?? ""
            textHTML += renderTagline(tgSlot, content: tgText, isLight: isLight, pad: pad, headlineColor: headlineColor)
        }

        // Headline
        let hlContent = shot.headline ?? hl.preview ?? ""
        textHTML += renderHeadline(hl, content: hlContent, isLight: isLight, pad: pad, headlineColor: headlineColor)

        // Subheading
        if let subSlot = screenLayout.subheading {
            let subText = shot.body ?? subSlot.preview ?? ""
            textHTML += renderSubheading(subSlot, content: subText, isLight: isLight, pad: pad)
        }

        // Trust marks (hero)
        if let marks = shot.trustMarks, !marks.isEmpty {
            textHTML += renderTrustMarks(marks, headlineSlot: hl, headlineContent: hlContent, isLight: isLight)
        }

        // Floating badges
        textHTML += renderBadges(shot.badges, headlineSlot: hl, isLight: isLight)

        // Devices
        var devHTML = ""
        let devSlots = screenLayout.devices.isEmpty && shot.type == .hero
            ? [DeviceSlot(x: 0.5, y: 0.42, width: 0.65)]
            : screenLayout.devices
        for (devIndex, dev) in devSlots.enumerated() {
            let screenshotFile = devIndex < shot.screenshots.count ? shot.screenshots[devIndex] : ""
            devHTML += renderDevice(dev, screenshot: screenshotFile, isLight: isLight)
        }

        // Decorations (ambient shapes + text/emoji labels)
        let decoHTML = renderDecorations(screenLayout.decorations, isLight: isLight)

        let template = loadTemplate("screen")
        return HTMLComposer.render(template, with: [
            "background": bg,
            "textHTML": textHTML,
            "deviceHTML": devHTML,
            "decorationHTML": decoHTML,
        ])
    }

    // MARK: - Text Elements

    /// Render a tagline (small caps text above headline).
    public static func renderTagline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let taglineColor = headlineColor ?? (isLight ? "rgba(0,0,0,0.40)" : "rgba(255,255,255,0.45)")
        let template = loadTemplate("tagline")
        return HTMLComposer.render(template, with: [
            "top": fmt(slot.y * 100),
            "pad": fmt(pad),
            "weight": "\(slot.weight)",
            "fontSize": fmt(slot.size * 100),
            "color": taglineColor,
            "align": slot.align,
            "content": content,
        ])
    }

    /// Render the headline text.
    public static func renderHeadline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let headlineColor = headlineColor ?? (isLight ? "#000" : "#fff")
        let hlText = content.replacingOccurrences(of: "\n", with: "<br>")
        let template = loadTemplate("headline")
        return HTMLComposer.render(template, with: [
            "top": fmt(slot.y * 100),
            "pad": fmt(pad),
            "weight": "\(slot.weight)",
            "fontSize": fmt(slot.size * 100),
            "color": headlineColor,
            "align": slot.align,
            "content": hlText,
        ])
    }

    /// Render subheading text below headline.
    public static func renderSubheading(_ slot: TextSlot, content: String, isLight: Bool, pad: Double) -> String {
        guard !content.isEmpty else { return "" }
        let bodyColor = isLight ? "#1a1a1a" : "rgba(255,255,255,0.7)"
        let subContent = content.replacingOccurrences(of: "\n", with: "<br>")
        let template = loadTemplate("subheading")
        return HTMLComposer.render(template, with: [
            "top": fmt(slot.y * 100),
            "pad": fmt(pad),
            "padRight": fmt(pad + 3),
            "weight": "\(slot.weight)",
            "fontSize": fmt(slot.size * 100),
            "color": bodyColor,
            "align": slot.align,
            "content": subContent,
        ])
    }

    // MARK: - Badges & Trust Marks

    /// Render floating badge pills positioned top-right area.
    public static func renderBadges(_ badges: [String], headlineSlot hl: TextSlot, isLight: Bool) -> String {
        guard !badges.isEmpty else { return "" }
        let badgeBg = isLight ? "rgba(0,0,0,0.07)" : "rgba(255,255,255,0.12)"
        let badgeColor = isLight ? "#1a1a1a" : "#fff"
        let badgeBorder = isLight ? "rgba(0,0,0,0.08)" : "rgba(255,255,255,0.15)"
        let badgeTop = hl.y * 100 + 1.0
        let template = loadTemplate("badge")
        var html = ""
        for (i, badge) in badges.enumerated() {
            let bx = hl.align == "left" ? 65.0 + Double(i % 2) * 12.0 : 60.0 + Double(i % 2) * 15.0
            let by = badgeTop + Double(i) * 7.0
            let bSize = fmt(hl.size * 100 * 0.28)
            html += HTMLComposer.render(template, with: [
                "left": fmt(bx),
                "top": fmt(by),
                "badgeBg": badgeBg,
                "badgeBorder": badgeBorder,
                "fontSize": bSize,
                "color": badgeColor,
                "text": badge,
            ])
        }
        return html
    }

    /// Render trust marks (hero badges) positioned below headline.
    public static func renderTrustMarks(
        _ marks: [String],
        headlineSlot hl: TextSlot,
        headlineContent: String,
        isLight: Bool
    ) -> String {
        guard !marks.isEmpty else { return "" }
        let badgeBg = isLight ? "rgba(0,0,0,0.07)" : "rgba(255,255,255,0.12)"
        let trustColor = isLight ? "rgba(0,0,0,0.55)" : "rgba(255,255,255,0.6)"
        let pad = 5.0
        let hlLines = Double(headlineContent.components(separatedBy: "\n").count)
        let afterHeading = hl.y * 100 + hlLines * hl.size * 100 * 1.0 + 1
        let markSize = fmt(hl.size * 100 * 0.28)
        let markItems = marks.map { mark in
            ["text": mark, "badgeBg": badgeBg, "fontSize": markSize, "color": trustColor]
        }
        let template = loadTemplate("trust-marks")
        return HTMLComposer.render(template, with: [
            "top": fmt(afterHeading),
            "pad": fmt(pad),
            "marks": markItems,
        ])
    }

    // MARK: - Device

    /// Render a device frame — real screenshot or wireframe.
    public static func renderDevice(_ slot: DeviceSlot, screenshot: String, isLight: Bool) -> String {
        let hasScreenshot = !screenshot.isEmpty
        let dw = fmt(slot.width * 100)
        let dl = fmt((slot.x - slot.width / 2) * 100)
        let dt = fmt(slot.y * 100)

        if hasScreenshot {
            let template = loadTemplate("device-screenshot")
            return HTMLComposer.render(template, with: [
                "left": dl,
                "top": dt,
                "width": dw,
                "screenshot": screenshot,
            ])
        } else {
            let shadow = isLight ? "0.12" : "0.35"
            let frameBg = isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.08)"
            let frameBorder2 = isLight ? "rgba(0,0,0,0.12)" : "rgba(255,255,255,0.15)"

            let outerStyle: String
            let frameOverlay: String
            if let dataURL = phoneFrameDataURL {
                frameOverlay = "<img src=\"\(dataURL)\" style=\"position:absolute;inset:0;width:100%;height:100%;z-index:2;pointer-events:none\" alt=\"\">"
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)))"
            } else {
                frameOverlay = ""
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)));background:\(frameBg);border-radius:12%/5.5%;border:1.5px solid \(frameBorder2);overflow:hidden"
            }

            let wireframeHTML = renderWireframe(isLight: isLight)
            let template = loadTemplate("device-wireframe")
            return HTMLComposer.render(template, with: [
                "left": dl,
                "top": dt,
                "width": dw,
                "outerStyle": outerStyle,
                "wireframeHTML": wireframeHTML,
                "frameOverlay": frameOverlay,
            ])
        }
    }

    // MARK: - Decorations

    /// Render decorations (ambient shapes + text/emoji labels) using `cqi` units.
    public static func renderDecorations(_ decorations: [Decoration], isLight: Bool) -> String {
        guard !decorations.isEmpty else { return "" }

        var html = ""
        let defaultColor = isLight ? "rgba(0,0,0,0.25)" : "rgba(255,255,255,0.25)"
        let animations = Set(decorations.compactMap(\.animation))
        let template = loadTemplate("decoration")

        for (i, deco) in decorations.enumerated() {
            let color = deco.color ?? defaultColor
            let bg = deco.background ?? "transparent"
            let radius = deco.borderRadius ?? "50%"
            let animStyle = deco.animation.map { "animation:td-\($0.rawValue) \(3 + i % 4)s ease-in-out infinite;" } ?? ""

            let content: String
            switch deco.shape {
            case .label(let text): content = text
            case .gem: content = "◆"
            case .orb: content = "●"
            case .sparkle: content = "✦"
            case .arrow: content = "›"
            }

            html += HTMLComposer.render(template, with: [
                "left": fmt(deco.x * 100),
                "top": fmt(deco.y * 100),
                "fontSize": fmt(deco.size * 100),
                "opacity": fmt(deco.opacity),
                "background": bg,
                "color": color,
                "borderRadius": radius,
                "animStyle": animStyle,
                "content": content,
            ])
        }

        // Keyframes for animated decorations
        if !animations.isEmpty {
            html += "<style>"
            for anim in animations.sorted(by: { $0.rawValue < $1.rawValue }) {
                html += keyframeCSS(for: anim)
            }
            html += "</style>"
        }

        return html
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

    // MARK: - Page Wrapper

    /// Wrap a rendered screen fragment in a full HTML page.
    public static func wrapPage(_ inner: String, fillViewport: Bool = false) -> String {
        let styles = buildPageStyles(
            previewStyle: fillViewport
                ? "width:100%;height:100%;container-type:inline-size"
                : "width:320px;aspect-ratio:1320/2868;container-type:inline-size",
            bodyStyle: fillViewport
                ? "margin:0;overflow:hidden"
                : "display:flex;justify-content:center;align-items:center;min-height:100vh;background:#111",
            htmlHeight: fillViewport ? "html,body{width:100%;height:100%}" : ""
        )
        let template = loadTemplate("page-wrapper")
        return HTMLComposer.render(template, with: [
            "styles": styles,
            "inner": inner,
        ])
    }

    /// Build the full CSS string for page-wrapper. Shared with `ThemedPage`.
    public static func buildPageStyles(previewStyle: String, bodyStyle: String, htmlHeight: String) -> String {
        "*{margin:0;padding:0;box-sizing:border-box}\(htmlHeight)body{\(bodyStyle)}.preview{\(previewStyle)}"
    }

    // MARK: - Preview

    /// Render a gallery preview page — multiple screens in a horizontal strip.
    public static func renderPreviewPage(_ gallery: Gallery) -> String {
        let screens = gallery.renderAll()
        guard !screens.isEmpty else { return "" }

        let screenTemplate = loadTemplate("preview-screen")
        let screenDivs = screens.map { screen in
            HTMLComposer.render(screenTemplate, with: ["screen": screen])
        }.joined()

        let template = loadTemplate("preview-page")
        return HTMLComposer.render(template, with: ["screenDivs": screenDivs])
    }

    // MARK: - Internal Helpers

    private static func isLightBackground(_ bg: String) -> Bool {
        let lightHex = ["#f", "#F", "#e", "#E", "#d", "#D", "#c", "#C", "#b", "#B", "#a8", "#A8", "#9"]
        return lightHex.contains(where: { bg.contains($0) })
    }

    nonisolated(unsafe) public static var phoneFrameDataURL: String?

    private static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private static func renderWireframe(isLight: Bool) -> String {
        let scr = isLight ? "rgba(255,255,255,0.65)" : "rgba(255,255,255,0.06)"
        let ui = isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.06)"
        let ui2 = isLight ? "rgba(0,0,0,0.10)" : "rgba(255,255,255,0.09)"
        let uitx = isLight ? "rgba(0,0,0,0.30)" : "rgba(255,255,255,0.25)"
        let template = loadTemplate("wireframe")
        return HTMLComposer.render(template, with: [
            "scr": scr,
            "ui": ui,
            "ui2": ui2,
            "uitx": uitx,
        ])
    }

    /// Load the page-wrapper template. Shared by `wrapPage()` and `ThemedPage`.
    public static func loadPageWrapperTemplate() -> String {
        loadTemplate("page-wrapper")
    }

    /// Load an HTML template by name, falling back to empty string.
    static func loadTemplate(_ name: String) -> String {
        templateRepository.template(named: name) ?? ""
    }
}

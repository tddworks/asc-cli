import Foundation

/// Renders App Store screenshot screens as HTML.
///
/// Builds a context dictionary from domain models, then delegates all HTML
/// rendering to external template files via `HTMLTemplateRepository`.
///
/// **OCP:** To change the visual output, swap templates — don't modify this code.
/// Templates own all HTML structure, CSS, conditionals, and loops.
/// This renderer only prepares data.
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
        let template = loadTemplate("screen")
        return HTMLComposer.render(template, with: context)
    }

    /// Build the full context dictionary for a screen template.
    /// Public so custom renderers can inspect/modify the context before rendering.
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
                let taglineColor = headlineColor
                context["tagline"] = [
                    "top": fmt(tgSlot.y * 100),
                    "pad": fmt(pad),
                    "weight": "\(tgSlot.weight)",
                    "fontSize": fmt(tgSlot.size * 100),
                    "color": taglineColor,
                    "align": tgSlot.align,
                    "content": tgText,
                ]
            }
        }

        // Headline
        let hlContent = shot.headline ?? hl.preview ?? ""
        if !hlContent.isEmpty {
            let hlText = hlContent.replacingOccurrences(of: "\n", with: "<br>")
            context["headline"] = [
                "top": fmt(hl.y * 100),
                "pad": fmt(pad),
                "weight": "\(hl.weight)",
                "fontSize": fmt(hl.size * 100),
                "color": headlineColor,
                "align": hl.align,
                "content": hlText,
            ]
        }

        // Subheading
        if let subSlot = screenLayout.subheading {
            let subText = shot.body ?? subSlot.preview ?? ""
            if !subText.isEmpty {
                let bodyColor = isLight ? "#1a1a1a" : "rgba(255,255,255,0.7)"
                let subContent = subText.replacingOccurrences(of: "\n", with: "<br>")
                context["subheading"] = [
                    "top": fmt(subSlot.y * 100),
                    "pad": fmt(pad),
                    "padRight": fmt(pad + 3),
                    "weight": "\(subSlot.weight)",
                    "fontSize": fmt(subSlot.size * 100),
                    "color": bodyColor,
                    "align": subSlot.align,
                    "content": subContent,
                ]
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
            let badgeBg = isLight ? "rgba(0,0,0,0.07)" : "rgba(255,255,255,0.12)"
            let badgeColor = isLight ? "#1a1a1a" : "#fff"
            let badgeBorder = isLight ? "rgba(0,0,0,0.08)" : "rgba(255,255,255,0.15)"
            let badgeTop = hl.y * 100 + 1.0
            context["badges"] = shot.badges.enumerated().map { (i, badge) in
                let bx = hl.align == "left" ? 65.0 + Double(i % 2) * 12.0 : 60.0 + Double(i % 2) * 15.0
                let by = badgeTop + Double(i) * 7.0
                return [
                    "left": fmt(bx),
                    "top": fmt(by),
                    "badgeBg": badgeBg,
                    "badgeBorder": badgeBorder,
                    "fontSize": fmt(hl.size * 100 * 0.28),
                    "color": badgeColor,
                    "text": badge,
                ]
            }
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
            let animations = Set(screenLayout.decorations.compactMap(\.animation))
            context["decorations"] = screenLayout.decorations.enumerated().map { (i, deco) in
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
            if !animations.isEmpty {
                context["keyframeStyles"] = animations.sorted(by: { $0.rawValue < $1.rawValue })
                    .map { keyframeCSS(for: $0) }.joined()
            }
        }

        return context
    }

    // MARK: - Device Context

    private static func buildDeviceContext(_ slot: DeviceSlot, screenshot: String, isLight: Bool) -> [String: Any] {
        let dl = fmt((slot.x - slot.width / 2) * 100)
        let dt = fmt(slot.y * 100)
        let dw = fmt(slot.width * 100)
        let hasScreenshot = !screenshot.isEmpty

        if hasScreenshot {
            return [
                "left": dl, "top": dt, "width": dw,
                "hasScreenshot": "1",
                "screenshot": screenshot,
            ]
        } else {
            let shadow = isLight ? "0.12" : "0.35"
            let frameBg = isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.08)"
            let frameBorder = isLight ? "rgba(0,0,0,0.12)" : "rgba(255,255,255,0.15)"

            let outerStyle: String
            let frameOverlay: String
            if let dataURL = phoneFrameDataURL {
                frameOverlay = "<img src=\"\(dataURL)\" style=\"position:absolute;inset:0;width:100%;height:100%;z-index:2;pointer-events:none\" alt=\"\">"
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)))"
            } else {
                frameOverlay = ""
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)));background:\(frameBg);border-radius:12%/5.5%;border:1.5px solid \(frameBorder);overflow:hidden"
            }

            let wireframeHTML = buildWireframeHTML(isLight: isLight)
            return [
                "left": dl, "top": dt, "width": dw,
                "hasWireframe": "1",
                "outerStyle": outerStyle,
                "wireframeHTML": wireframeHTML,
                "frameOverlay": frameOverlay,
            ]
        }
    }

    // MARK: - Wireframe

    private static func buildWireframeHTML(isLight: Bool) -> String {
        let scr = isLight ? "rgba(255,255,255,0.65)" : "rgba(255,255,255,0.06)"
        let ui = isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.06)"
        let ui2 = isLight ? "rgba(0,0,0,0.10)" : "rgba(255,255,255,0.09)"
        let uitx = isLight ? "rgba(0,0,0,0.30)" : "rgba(255,255,255,0.25)"
        let template = loadTemplate("wireframe")
        return HTMLComposer.render(template, with: ["scr": scr, "ui": ui, "ui2": ui2, "uitx": uitx])
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
        return HTMLComposer.render(template, with: ["styles": styles, "inner": inner])
    }

    /// Build the full CSS string for page-wrapper. Shared with `ThemedPage`.
    public static func buildPageStyles(previewStyle: String, bodyStyle: String, htmlHeight: String) -> String {
        "*{margin:0;padding:0;box-sizing:border-box}\(htmlHeight)body{\(bodyStyle)}.preview{\(previewStyle)}"
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
        let screenDivs = screens.map { screen in
            HTMLComposer.render(screenTemplate, with: ["screen": screen])
        }.joined()

        let template = loadTemplate("preview-page")
        return HTMLComposer.render(template, with: ["screenDivs": screenDivs])
    }

    // MARK: - Backward-Compatible Public Methods

    /// Render a tagline — delegates to screen template internally.
    /// Kept for backward compatibility with tests.
    public static func renderTagline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let color = headlineColor ?? (isLight ? "rgba(0,0,0,0.40)" : "rgba(255,255,255,0.45)")
        let template = loadTemplate("tagline")
        if !template.isEmpty {
            return HTMLComposer.render(template, with: [
                "top": fmt(slot.y * 100), "pad": fmt(pad), "weight": "\(slot.weight)",
                "fontSize": fmt(slot.size * 100), "color": color, "align": slot.align, "content": content,
            ])
        }
        return "<div style=\"position:absolute;top:\(fmt(slot.y * 100))%;left:\(fmt(pad))%;right:\(fmt(pad))%;z-index:4;font-weight:\(slot.weight);font-size:\(fmt(slot.size * 100))cqi;color:\(color);letter-spacing:0.1em;text-transform:uppercase;text-align:\(slot.align);white-space:pre-line\">\(content)</div>"
    }

    /// Render the headline text.
    public static func renderHeadline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let color = headlineColor ?? (isLight ? "#000" : "#fff")
        let hlText = content.replacingOccurrences(of: "\n", with: "<br>")
        let template = loadTemplate("headline")
        if !template.isEmpty {
            return HTMLComposer.render(template, with: [
                "top": fmt(slot.y * 100), "pad": fmt(pad), "weight": "\(slot.weight)",
                "fontSize": fmt(slot.size * 100), "color": color, "align": slot.align, "content": hlText,
            ])
        }
        return "<div style=\"position:absolute;top:\(fmt(slot.y * 100))%;left:\(fmt(pad))%;right:\(fmt(pad))%;z-index:4;font-weight:\(slot.weight);font-size:\(fmt(slot.size * 100))cqi;color:\(color);line-height:0.92;letter-spacing:-0.03em;text-align:\(slot.align);white-space:pre-line\">\(hlText)</div>"
    }

    /// Render subheading text below headline.
    public static func renderSubheading(_ slot: TextSlot, content: String, isLight: Bool, pad: Double) -> String {
        guard !content.isEmpty else { return "" }
        let bodyColor = isLight ? "#1a1a1a" : "rgba(255,255,255,0.7)"
        let subContent = content.replacingOccurrences(of: "\n", with: "<br>")
        let template = loadTemplate("subheading")
        if !template.isEmpty {
            return HTMLComposer.render(template, with: [
                "top": fmt(slot.y * 100), "pad": fmt(pad), "padRight": fmt(pad + 3),
                "weight": "\(slot.weight)", "fontSize": fmt(slot.size * 100),
                "color": bodyColor, "align": slot.align, "content": subContent,
            ])
        }
        return "<div style=\"position:absolute;top:\(fmt(slot.y * 100))%;left:\(fmt(pad))%;right:\(fmt(pad + 3))%;z-index:4;font-weight:\(slot.weight);font-size:\(fmt(slot.size * 100))cqi;color:\(bodyColor);line-height:1.4;text-align:\(slot.align)\">\(subContent)</div>"
    }

    /// Render floating badge pills.
    public static func renderBadges(_ badges: [String], headlineSlot hl: TextSlot, isLight: Bool) -> String {
        guard !badges.isEmpty else { return "" }
        let badgeBg = isLight ? "rgba(0,0,0,0.07)" : "rgba(255,255,255,0.12)"
        let badgeColor = isLight ? "#1a1a1a" : "#fff"
        let badgeBorder = isLight ? "rgba(0,0,0,0.08)" : "rgba(255,255,255,0.15)"
        let badgeTop = hl.y * 100 + 1.0
        var html = ""
        for (i, badge) in badges.enumerated() {
            let bx = hl.align == "left" ? 65.0 + Double(i % 2) * 12.0 : 60.0 + Double(i % 2) * 15.0
            let by = badgeTop + Double(i) * 7.0
            let bSize = fmt(hl.size * 100 * 0.28)
            html += "<div style=\"position:absolute;left:\(fmt(bx))%;top:\(fmt(by))%;z-index:5;background:\(badgeBg);border:1px solid \(badgeBorder);border-radius:100px;padding:0.3cqi 0.8cqi;font-size:\(bSize)cqi;font-weight:700;color:\(badgeColor);backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);white-space:nowrap\">\(badge)</div>"
        }
        return html
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
        var html = "<div style=\"position:absolute;top:\(fmt(afterHeading))%;left:\(fmt(pad))%;z-index:4;display:flex;gap:4px;flex-wrap:wrap\">"
        for mark in marks {
            html += "<span style=\"background:\(badgeBg);border-radius:5px;padding:0.3cqi 0.8cqi;font-size:\(markSize)cqi;font-weight:700;color:\(trustColor);letter-spacing:0.04em\">\(mark)</span>"
        }
        html += "</div>"
        return html
    }

    /// Render a device frame — real screenshot or wireframe.
    public static func renderDevice(_ slot: DeviceSlot, screenshot: String, isLight: Bool) -> String {
        let ctx = buildDeviceContext(slot, screenshot: screenshot, isLight: isLight)
        let hasScreenshot = !screenshot.isEmpty
        let dl = ctx["left"] as? String ?? ""
        let dt = ctx["top"] as? String ?? ""
        let dw = ctx["width"] as? String ?? ""
        if hasScreenshot {
            return "<div style=\"position:absolute;left:\(dl)%;top:\(dt)%;width:\(dw)%;z-index:2\"><img src=\"\(screenshot)\" style=\"width:100%;display:block\" alt=\"\"></div>"
        } else {
            let outerStyle = ctx["outerStyle"] as? String ?? ""
            let wireframeHTML = ctx["wireframeHTML"] as? String ?? ""
            let frameOverlay = ctx["frameOverlay"] as? String ?? ""
            return "<div style=\"position:absolute;left:\(dl)%;top:\(dt)%;width:\(dw)%;z-index:2\"><div style=\"\(outerStyle)\">\(wireframeHTML)\(frameOverlay)</div></div>"
        }
    }

    /// Render decorations.
    public static func renderDecorations(_ decorations: [Decoration], isLight: Bool) -> String {
        guard !decorations.isEmpty else { return "" }
        let defaultColor = isLight ? "rgba(0,0,0,0.25)" : "rgba(255,255,255,0.25)"
        let animations = Set(decorations.compactMap(\.animation))
        var html = ""
        for (i, deco) in decorations.enumerated() {
            let color = deco.color ?? defaultColor
            let bg = deco.background ?? "transparent"
            let radius = deco.borderRadius ?? "50%"
            let animStyle = deco.animation.map { "animation:td-\($0.rawValue) \(3 + i % 4)s ease-in-out infinite;" } ?? ""
            html += "<div style=\"position:absolute;left:\(fmt(deco.x * 100))%;top:\(fmt(deco.y * 100))%;z-index:3;font-size:\(fmt(deco.size * 100))cqi;opacity:\(fmt(deco.opacity));background:\(bg);color:\(color);border-radius:\(radius);padding:0.3cqi 0.8cqi;pointer-events:none;white-space:nowrap;\(animStyle)\">\(shapeContent(deco.shape))</div>"
        }
        if !animations.isEmpty {
            html += "<style>"
            for anim in animations.sorted(by: { $0.rawValue < $1.rawValue }) {
                html += keyframeCSS(for: anim)
            }
            html += "</style>"
        }
        return html
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

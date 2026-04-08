import Foundation

/// Renders App Store screenshot screens as HTML.
///
/// Uses `cqi` units + `container-type:inline-size` for responsive scaling.
/// Screen aspect ratio: 1320/2868 (iPhone App Store screenshot).
public enum GalleryHTMLRenderer {

    /// Render a single AppShot as an HTML fragment for one screen.
    public static func renderScreen(
        _ shot: AppShot,
        screenLayout: ScreenLayout,
        palette: GalleryPalette
    ) -> String {
        let bg = palette.background
        let hl = screenLayout.headline
        // Use explicit textColor if set, otherwise auto-detect from background
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

        return "<div style=\"background:\(bg);position:relative;overflow:hidden;container-type:inline-size;width:100%;height:100%\">"
            + "\(textHTML)\(devHTML)\(decoHTML)"
            + "</div>"
    }

    // MARK: - Text Elements

    /// Render a tagline (small caps text above headline).
    public static func renderTagline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let taglineColor = headlineColor ?? (isLight ? "rgba(0,0,0,0.40)" : "rgba(255,255,255,0.45)")
        let tgSize = fmt(slot.size * 100)
        return "<div style=\"position:absolute;top:\(fmt(slot.y * 100))%;left:\(fmt(pad))%;right:\(fmt(pad))%;z-index:4;"
            + "font-weight:\(slot.weight);font-size:\(tgSize)cqi;color:\(taglineColor);"
            + "letter-spacing:0.1em;text-transform:uppercase;text-align:\(slot.align);white-space:pre-line\">"
            + "\(content)</div>"
    }

    /// Render the headline text.
    public static func renderHeadline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let headlineColor = headlineColor ?? (isLight ? "#000" : "#fff")
        let hlSize = fmt(slot.size * 100)
        let hlText = content.replacingOccurrences(of: "\n", with: "<br>")
        return "<div style=\"position:absolute;top:\(fmt(slot.y * 100))%;left:\(fmt(pad))%;right:\(fmt(pad))%;z-index:4;"
            + "font-weight:\(slot.weight);font-size:\(hlSize)cqi;color:\(headlineColor);"
            + "line-height:0.92;letter-spacing:-0.03em;text-align:\(slot.align);white-space:pre-line\">"
            + "\(hlText)</div>"
    }

    /// Render subheading text below headline.
    public static func renderSubheading(_ slot: TextSlot, content: String, isLight: Bool, pad: Double) -> String {
        guard !content.isEmpty else { return "" }
        let bodyColor = isLight ? "#1a1a1a" : "rgba(255,255,255,0.7)"
        let subSize = fmt(slot.size * 100)
        let subContent = content.replacingOccurrences(of: "\n", with: "<br>")
        return "<div style=\"position:absolute;top:\(fmt(slot.y * 100))%;left:\(fmt(pad))%;right:\(fmt(pad + 3))%;z-index:4;"
            + "font-weight:\(slot.weight);font-size:\(subSize)cqi;color:\(bodyColor);line-height:1.4;text-align:\(slot.align)\">"
            + "\(subContent)</div>"
    }

    // MARK: - Badges & Trust Marks

    /// Render floating badge pills positioned top-right area.
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
            html += "<div style=\"position:absolute;left:\(fmt(bx))%;top:\(fmt(by))%;z-index:5;"
            html += "background:\(badgeBg);border:1px solid \(badgeBorder);border-radius:100px;"
            html += "padding:0.3cqi 0.8cqi;font-size:\(bSize)cqi;font-weight:700;color:\(badgeColor);"
            html += "backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);white-space:nowrap\">"
            html += "\(badge)</div>"
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
        var html = "<div style=\"position:absolute;top:\(fmt(afterHeading))%;left:\(fmt(pad))%;z-index:4;display:flex;gap:4px;flex-wrap:wrap\">"
        for mark in marks {
            html += "<span style=\"background:\(badgeBg);border-radius:5px;padding:0.3cqi 0.8cqi;font-size:\(markSize)cqi;font-weight:700;color:\(trustColor);letter-spacing:0.04em\">\(mark)</span>"
        }
        html += "</div>"
        return html
    }

    // MARK: - Device

    /// Render a device frame — real screenshot or wireframe.
    public static func renderDevice(_ slot: DeviceSlot, screenshot: String, isLight: Bool) -> String {
        let hasScreenshot = !screenshot.isEmpty
        let dw = fmt(slot.width * 100)
        let dl = fmt((slot.x - slot.width / 2) * 100)
        let dt = fmt(slot.y * 100)
        let shadow = isLight ? "0.12" : "0.35"
        let frameBg = isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.08)"
        let frameBorder2 = isLight ? "rgba(0,0,0,0.12)" : "rgba(255,255,255,0.15)"
        let scr = isLight ? "rgba(255,255,255,0.65)" : "rgba(255,255,255,0.06)"
        let ui = isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.06)"
        let ui2 = isLight ? "rgba(0,0,0,0.10)" : "rgba(255,255,255,0.09)"
        let uitx = isLight ? "rgba(0,0,0,0.30)" : "rgba(255,255,255,0.25)"

        var devHTML = "<div style=\"position:absolute;left:\(dl)%;top:\(dt)%;width:\(dw)%;z-index:2\">"

        if hasScreenshot {
            devHTML += "<img src=\"\(screenshot)\" style=\"width:100%;display:block\" alt=\"\">"
        } else {
            let outerStyle: String
            let frameOverlay: String
            if let dataURL = phoneFrameDataURL {
                frameOverlay = "<img src=\"\(dataURL)\" style=\"position:absolute;inset:0;width:100%;height:100%;z-index:2;pointer-events:none\" alt=\"\">"
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)))"
            } else {
                frameOverlay = ""
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)));background:\(frameBg);border-radius:12%/5.5%;border:1.5px solid \(frameBorder2);overflow:hidden"
            }
            devHTML += "<div style=\"\(outerStyle)\">"
            devHTML += renderWireframe(isLight: isLight, scr: scr, ui: ui, ui2: ui2, uitx: uitx)
            devHTML += "\(frameOverlay)</div>"
        }

        devHTML += "</div>"
        return devHTML
    }

    // MARK: - Decorations

    /// Render decorations (ambient shapes + text/emoji labels) using `cqi` units.
    public static func renderDecorations(_ decorations: [Decoration], isLight: Bool) -> String {
        guard !decorations.isEmpty else { return "" }

        var html = ""
        let defaultColor = isLight ? "rgba(0,0,0,0.25)" : "rgba(255,255,255,0.25)"
        let animations = Set(decorations.compactMap(\.animation))

        for (i, deco) in decorations.enumerated() {
            let left = fmt(deco.x * 100)
            let top = fmt(deco.y * 100)
            let fontSize = fmt(deco.size * 100)
            let color = deco.color ?? defaultColor
            let bg = deco.background ?? "transparent"
            let radius = deco.borderRadius ?? "50%"
            let animStyle = deco.animation.map { "animation:td-\($0.rawValue) \(3 + i % 4)s ease-in-out infinite;" } ?? ""

            let content: String
            switch deco.shape {
            case .label(let text):
                content = text
            case .gem:
                content = "◆"
            case .orb:
                content = "●"
            case .sparkle:
                content = "✦"
            case .arrow:
                content = "›"
            }

            html += "<div style=\"position:absolute;left:\(left)%;top:\(top)%;z-index:3;"
            html += "font-size:\(fontSize)cqi;opacity:\(fmt(deco.opacity));"
            html += "background:\(bg);color:\(color);"
            html += "border-radius:\(radius);padding:0.3cqi 0.8cqi;"
            html += "pointer-events:none;white-space:nowrap;\(animStyle)\">"
            html += "\(content)</div>"
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
        let previewStyle = fillViewport
            ? "width:100%;height:100%;container-type:inline-size"
            : "width:320px;aspect-ratio:1320/2868;container-type:inline-size"
        let bodyStyle = fillViewport
            ? "margin:0;overflow:hidden"
            : "display:flex;justify-content:center;align-items:center;min-height:100vh;background:#111"
        let htmlHeight = fillViewport ? "html,body{width:100%;height:100%}" : ""
        return "<!DOCTYPE html><html><head><meta charset=\"utf-8\">" +
            "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">" +
            "<style>*{margin:0;padding:0;box-sizing:border-box}" +
            "\(htmlHeight)" +
            "body{\(bodyStyle)}" +
            ".preview{\(previewStyle)}</style>" +
            "</head><body><div class=\"preview\">\(inner)</div></body></html>"
    }

    // MARK: - Preview

    /// Render a gallery preview page — multiple screens in a horizontal strip.
    public static func renderPreviewPage(_ gallery: Gallery) -> String {
        let screens = gallery.renderAll()
        guard !screens.isEmpty else { return "" }

        let screenDivs = screens.map { screen in
            "<div style=\"width:120px;aspect-ratio:1320/2868;border-radius:6px;overflow:hidden;flex-shrink:0;box-shadow:0 1px 4px rgba(0,0,0,0.06),0 4px 12px rgba(0,0,0,0.04)\">\(screen)</div>"
        }.joined()

        return """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <style>*{margin:0;padding:0;box-sizing:border-box}
        body{background:#dfe2e8;display:flex;align-items:flex-start;height:100vh;overflow:hidden;font-family:system-ui,-apple-system,sans-serif}
        .g{display:flex;gap:5px;padding:10px;align-items:flex-start}
        </style></head><body>
        <div class="g">\(screenDivs)</div>
        </body></html>
        """
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

    /// Adjust a hex color to reduced opacity for secondary text.
    private static func adjustOpacity(_ hex: String, _ alpha: Double) -> String {
        // Simple approach: return the color with alpha for CSS
        "\(hex)"  // For now, just use the color as-is — tagline uses its own opacity via letter-spacing
    }

    private static func renderWireframe(isLight: Bool, scr: String, ui: String, ui2: String, uitx: String) -> String {
        var html = "<div style=\"position:absolute;inset:2.6% 2.2%;background:\(scr);border-radius:8%/4%;overflow:hidden;z-index:1\">"
        html += "<div style=\"padding:5% 5% 0;display:flex;justify-content:space-between\">"
        html += "<div style=\"font-size:max(3.5px,1.6cqi);font-weight:600;color:\(uitx);font-family:system-ui\">9:41</div>"
        html += "<div style=\"display:flex;gap:1px;align-items:center\">"
        html += "<div style=\"width:max(3px,1.2cqi);height:max(3px,1.2cqi);border-radius:50%;background:\(uitx)\"></div>"
        html += "<div style=\"width:max(5px,2cqi);height:max(3px,1.2cqi);border-radius:1px;background:\(uitx)\"></div>"
        html += "</div></div>"
        html += "<div style=\"padding:3% 4% 0\">"
        html += "<div style=\"background:\(ui);border-radius:max(3px,1.5cqi);padding:4% 5%;margin-bottom:2%\">"
        html += "<div style=\"display:flex;gap:3%;align-items:center;margin-bottom:3%\">"
        html += "<div style=\"width:max(6px,3cqi);height:max(6px,3cqi);border-radius:50%;background:\(ui2)\"></div>"
        html += "<div><div style=\"height:max(1.5px,0.7cqi);width:max(14px,7cqi);background:\(ui2);border-radius:1px;margin-bottom:2px\"></div>"
        html += "<div style=\"height:max(1px,0.5cqi);width:max(9px,4.5cqi);background:\(ui2);border-radius:1px\"></div></div></div>"
        html += "<div style=\"aspect-ratio:16/9;background:\(ui2);border-radius:max(2px,1cqi);margin-bottom:3%\"></div>"
        html += "<div style=\"height:max(1.5px,0.7cqi);width:80%;background:\(ui2);border-radius:1px;margin-bottom:2%\"></div>"
        html += "<div style=\"height:max(1px,0.5cqi);width:55%;background:\(ui2);border-radius:1px\"></div></div>"
        html += "<div style=\"background:\(ui);border-radius:max(3px,1.5cqi);padding:4% 5%;margin-bottom:2%\">"
        html += "<div style=\"display:flex;gap:3%\">"
        html += "<div style=\"flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)\"></div>"
        html += "<div style=\"flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)\"></div>"
        html += "<div style=\"flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)\"></div></div></div>"
        html += "</div>"
        html += "<div style=\"position:absolute;bottom:1.2%;left:30%;right:30%;height:max(1.5px,0.6cqi);background:\(uitx);border-radius:4px\"></div>"
        html += "</div>"
        return html
    }
}

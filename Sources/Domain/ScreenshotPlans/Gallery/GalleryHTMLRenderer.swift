import Foundation

/// Renders App Store screenshot screens as HTML.
///
/// Uses `cqi` units + `container-type:inline-size` for responsive scaling.
/// Screen aspect ratio: 1320/2868 (iPhone App Store screenshot).
public enum GalleryHTMLRenderer {

    /// Render a single AppShot as an HTML fragment for one screen.
    public static func renderScreen(
        _ shot: AppShot,
        screenTemplate: ScreenTemplate,
        palette: GalleryPalette
    ) -> String {
        let bg = palette.background
        let hl = screenTemplate.headline
        let hlSize = fmt(hl.size * 100)
        let isLight = isLightBackground(bg)
        let headlineColor = isLight ? "#000" : "#fff"
        let taglineColor = isLight ? "rgba(0,0,0,0.40)" : "rgba(255,255,255,0.45)"
        let bodyColor = isLight ? "#1a1a1a" : "rgba(255,255,255,0.7)"
        let badgeBg = isLight ? "rgba(0,0,0,0.07)" : "rgba(255,255,255,0.12)"
        let badgeColor = isLight ? "#1a1a1a" : "#fff"
        let badgeBorder = isLight ? "rgba(0,0,0,0.08)" : "rgba(255,255,255,0.15)"
        let trustColor = isLight ? "rgba(0,0,0,0.55)" : "rgba(255,255,255,0.6)"

        let pad = 5.0
        var textTop = hl.y * 100
        var textHTML = ""

        // Tagline
        if let tagline = shot.tagline, !tagline.isEmpty {
            let tgSize = fmt(hl.size * 100 * 0.45)
            textHTML += "<div style=\"position:absolute;top:\(fmt(textTop))%;left:\(fmt(pad))%;right:\(fmt(pad))%;z-index:4;"
            textHTML += "font-weight:700;font-size:\(tgSize)cqi;color:\(taglineColor);"
            textHTML += "letter-spacing:0.1em;text-transform:uppercase;text-align:\(hl.align);white-space:pre-line\">"
            textHTML += "\(tagline)</div>"
            textTop += hl.size * 100 * 0.45 * 1.4 + 0.5
        }

        // Headline
        let hlText = (shot.headline ?? "").replacingOccurrences(of: "\n", with: "<br>")
        textHTML += "<div style=\"position:absolute;top:\(fmt(textTop))%;left:\(fmt(pad))%;right:\(fmt(pad))%;z-index:4;"
        textHTML += "font-weight:\(hl.weight);font-size:\(hlSize)cqi;color:\(headlineColor);"
        textHTML += "line-height:0.92;letter-spacing:-0.03em;text-align:\(hl.align);white-space:pre-line\">"
        textHTML += "\(hlText)</div>"

        let hlLines = Double((shot.headline ?? "").components(separatedBy: "\n").count)
        let afterHeading = textTop + hlLines * hl.size * 100 * 1.0 + 1

        // Body text
        if let body = shot.body, !body.isEmpty {
            let bodySize = fmt(hl.size * 100 * 0.4)
            let bodyText = body.replacingOccurrences(of: "\n", with: "<br>")
            textHTML += "<div style=\"position:absolute;top:\(fmt(afterHeading))%;left:\(fmt(pad))%;right:\(fmt(pad + 3))%;z-index:4;"
            textHTML += "font-weight:500;font-size:\(bodySize)cqi;color:\(bodyColor);line-height:1.4;text-align:\(hl.align)\">"
            textHTML += "\(bodyText)</div>"
        }

        // Trust marks (hero)
        if let marks = shot.trustMarks, !marks.isEmpty {
            let markSize = fmt(hl.size * 100 * 0.28)
            textHTML += "<div style=\"position:absolute;top:\(fmt(afterHeading))%;left:\(fmt(pad))%;z-index:4;display:flex;gap:4px;flex-wrap:wrap\">"
            for mark in marks {
                textHTML += "<span style=\"background:\(badgeBg);border-radius:5px;padding:0.3cqi 0.8cqi;font-size:\(markSize)cqi;font-weight:700;color:\(trustColor);letter-spacing:0.04em\">\(mark)</span>"
            }
            textHTML += "</div>"
        }

        // Floating badges — positioned top-right, stacking down
        if !shot.badges.isEmpty {
            let badgeTop = hl.y * 100
            for (i, badge) in shot.badges.enumerated() {
                let bx = hl.align == "left" ? 62.0 + Double(i % 2) * 16.0 : 55.0 + Double(i % 2) * 20.0
                let by = badgeTop + Double(i) * 9.0
                let bSize = fmt(hl.size * 100 * 0.3)
                textHTML += "<div style=\"position:absolute;left:\(fmt(bx))%;top:\(fmt(by))%;z-index:5;"
                textHTML += "background:\(badgeBg);border:1px solid \(badgeBorder);border-radius:100px;"
                textHTML += "padding:0.3cqi 0.8cqi;font-size:\(bSize)cqi;font-weight:700;color:\(badgeColor);"
                textHTML += "backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);white-space:nowrap\">"
                textHTML += "\(badge)</div>"
            }
        }

        // Device — wireframe phone
        var devHTML = ""
        if let dev = screenTemplate.device {
            let dw = fmt(dev.width * 100)
            let dl = fmt((dev.x - dev.width / 2) * 100)
            let dt = fmt(dev.y * 100)
            let shadow = isLight ? "0.12" : "0.35"
            let frameBg = isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.08)"
            let frameBorder2 = isLight ? "rgba(0,0,0,0.12)" : "rgba(255,255,255,0.15)"
            let scr = isLight ? "rgba(255,255,255,0.65)" : "rgba(255,255,255,0.06)"
            let ui = isLight ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.06)"
            let ui2 = isLight ? "rgba(0,0,0,0.10)" : "rgba(255,255,255,0.09)"
            let uitx = isLight ? "rgba(0,0,0,0.30)" : "rgba(255,255,255,0.25)"

            let frameOverlay: String
            let outerStyle: String
            if let dataURL = phoneFrameDataURL {
                frameOverlay = "<img src=\"\(dataURL)\" style=\"position:absolute;inset:0;width:100%;height:100%;z-index:2;pointer-events:none\" alt=\"\">"
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)))"
            } else {
                frameOverlay = ""
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)));background:\(frameBg);border-radius:12%/5.5%;border:1.5px solid \(frameBorder2);overflow:hidden"
            }

            devHTML += "<div style=\"position:absolute;left:\(dl)%;top:\(dt)%;width:\(dw)%;z-index:2\">"
            devHTML += "<div style=\"\(outerStyle)\">"
            devHTML += "<div style=\"position:absolute;inset:2.6% 2.2%;background:\(scr);border-radius:8%/4%;overflow:hidden;z-index:1\">"
            devHTML += "<div style=\"padding:5% 5% 0;display:flex;justify-content:space-between\">"
            devHTML += "<div style=\"font-size:max(3.5px,1.6cqi);font-weight:600;color:\(uitx);font-family:system-ui\">9:41</div>"
            devHTML += "<div style=\"display:flex;gap:1px;align-items:center\">"
            devHTML += "<div style=\"width:max(3px,1.2cqi);height:max(3px,1.2cqi);border-radius:50%;background:\(uitx)\"></div>"
            devHTML += "<div style=\"width:max(5px,2cqi);height:max(3px,1.2cqi);border-radius:1px;background:\(uitx)\"></div>"
            devHTML += "</div></div>"
            devHTML += "<div style=\"padding:3% 4% 0\">"
            devHTML += "<div style=\"background:\(ui);border-radius:max(3px,1.5cqi);padding:4% 5%;margin-bottom:2%\">"
            devHTML += "<div style=\"display:flex;gap:3%;align-items:center;margin-bottom:3%\">"
            devHTML += "<div style=\"width:max(6px,3cqi);height:max(6px,3cqi);border-radius:50%;background:\(ui2)\"></div>"
            devHTML += "<div><div style=\"height:max(1.5px,0.7cqi);width:max(14px,7cqi);background:\(ui2);border-radius:1px;margin-bottom:2px\"></div>"
            devHTML += "<div style=\"height:max(1px,0.5cqi);width:max(9px,4.5cqi);background:\(ui2);border-radius:1px\"></div></div></div>"
            devHTML += "<div style=\"aspect-ratio:16/9;background:\(ui2);border-radius:max(2px,1cqi);margin-bottom:3%\"></div>"
            devHTML += "<div style=\"height:max(1.5px,0.7cqi);width:80%;background:\(ui2);border-radius:1px;margin-bottom:2%\"></div>"
            devHTML += "<div style=\"height:max(1px,0.5cqi);width:55%;background:\(ui2);border-radius:1px\"></div></div>"
            devHTML += "<div style=\"background:\(ui);border-radius:max(3px,1.5cqi);padding:4% 5%;margin-bottom:2%\">"
            devHTML += "<div style=\"display:flex;gap:3%\">"
            devHTML += "<div style=\"flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)\"></div>"
            devHTML += "<div style=\"flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)\"></div>"
            devHTML += "<div style=\"flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)\"></div></div></div>"
            devHTML += "</div>"
            devHTML += "<div style=\"position:absolute;bottom:1.2%;left:30%;right:30%;height:max(1.5px,0.6cqi);background:\(uitx);border-radius:4px\"></div>"
            devHTML += "</div>"
            devHTML += "\(frameOverlay)</div></div>"
        }

        return "<div style=\"background:\(bg);position:relative;overflow:hidden;container-type:inline-size;width:100%;height:100%\">"
            + "\(textHTML)\(devHTML)"
            + "</div>"
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

    private static func isLightBackground(_ bg: String) -> Bool {
        let lightHex = ["#f", "#F", "#e", "#E", "#d", "#D", "#c", "#C", "#b", "#B", "#a8", "#A8", "#9"]
        return lightHex.contains(where: { bg.contains($0) })
    }

    // MARK: - Helpers

    nonisolated(unsafe) public static var phoneFrameDataURL: String?

    private static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

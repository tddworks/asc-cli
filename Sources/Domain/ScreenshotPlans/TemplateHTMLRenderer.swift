import Foundation

/// Renders self-contained HTML previews of `ScreenshotTemplate`.
///
/// Output uses `cqi` units + `container-type:inline-size` so it scales
/// to any container width. Includes a realistic wireframe iPhone with
/// status bar, UI cards, and the real iPhone frame PNG overlay.
public enum TemplateHTMLRenderer {

    /// Base64 data URL of the iPhone frame PNG.
    /// Set by infrastructure at startup (e.g. from plugin's iphone-frame.png).
    /// If nil, a CSS wireframe is used instead.
    nonisolated(unsafe) public static var phoneFrameDataURL: String?

    /// Render a complete HTML page (for saving as .html file).
    /// When `fillViewport` is true, the preview fills the entire viewport (for image export).
    public static func renderPage(_ template: ScreenshotTemplate, content: TemplateContent? = nil, fillViewport: Bool = false) -> String {
        let inner = render(template, content: content)
        let previewStyle = fillViewport
            ? "width:100%;height:100%;container-type:inline-size"
            : "width:320px;aspect-ratio:1320/2868;container-type:inline-size"
        let bodyStyle = fillViewport
            ? "margin:0;overflow:hidden"
            : "display:flex;justify-content:center;align-items:center;min-height:100vh;background:#111"
        let htmlHeight = fillViewport ? "html,body{width:100%;height:100%}" : ""
        return "<!DOCTYPE html><html><head><meta charset=\"utf-8\">" +
            "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">" +
            "<title>\(template.name)</title>" +
            "<style>*{margin:0;padding:0;box-sizing:border-box}" +
            "\(htmlHeight)" +
            "body{\(bodyStyle)}" +
            ".preview{\(previewStyle)}</style>" +
            "</head><body><div class=\"preview\">\(inner)</div></body></html>"
    }

    /// Render an inline HTML div (for embedding in any container).
    /// The container MUST have `container-type:inline-size` for `cqi` units to work.
    public static func render(_ template: ScreenshotTemplate, content: TemplateContent? = nil) -> String {
        let bgCSS = backgroundCSS(template.background)
        let lit = isLightColor(template.background)
        let textHTML = template.textSlots.map { renderText($0, content: content) }.joined()
        let deviceHTML = template.deviceSlots.map { renderDevice($0, lit: lit, screenshotFile: content?.screenshotFile) }.joined()

        return "<div style=\"width:100%;height:100%;background:\(bgCSS);" +
            "position:relative;overflow:hidden;container-type:inline-size\">" +
            "\(textHTML)\(deviceHTML)</div>"
    }

    // MARK: - Background

    private static func backgroundCSS(_ bg: SlideBackground) -> String {
        switch bg {
        case .solid(let color): return color
        case .gradient(let from, let to, let angle): return "linear-gradient(\(angle)deg,\(from),\(to))"
        }
    }

    private static func isLightColor(_ bg: SlideBackground) -> Bool {
        let hex: String
        switch bg {
        case .solid(let color): hex = color
        case .gradient(let from, _, _): hex = from
        }
        let h = hex.replacingOccurrences(of: "#", with: "")
        guard h.count == 6,
              let r = UInt8(h.prefix(2), radix: 16),
              let g = UInt8(h.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(h.dropFirst(4).prefix(2), radix: 16) else { return false }
        return (Int(r) * 299 + Int(g) * 587 + Int(b) * 114) / 1000 > 160
    }

    // MARK: - Text

    private static func renderText(_ slot: TemplateTextSlot, content: TemplateContent?) -> String {
        let text: String
        if let content {
            switch slot.role {
            case .heading: text = content.headline
            case .subheading: text = content.subtitle ?? ""
            case .tagline: text = content.tagline ?? slot.preview
            }
        } else {
            text = slot.preview
        }
        guard !text.isEmpty else { return "" }

        let display = text.replacingOccurrences(of: "\n", with: "<br>")
        let top = fmt(slot.y * 100)
        let size = fmt(slot.fontSize * 100)
        let align = slot.textAlign
        let left = align == "left"
            ? "left:\(fmt(slot.x * 100))%;right:5%"
            : "left:5%;right:5%"
        let font = slot.font.map { "'\($0)'," } ?? ""
        let fontFamily = "\(font)system-ui,-apple-system,sans-serif"

        var s = "position:absolute;top:\(top)%;\(left);text-align:\(align);z-index:2;"
        s += "color:\(slot.color);"
        s += "font-size:max(8px,\(size)cqi);"
        s += "font-weight:\(slot.fontWeight);"
        s += "line-height:\(slot.lineHeight ?? 1.1);"
        s += "font-family:\(fontFamily);"
        s += "font-style:\(slot.fontStyle ?? "normal");"
        s += "letter-spacing:\(slot.letterSpacing ?? "-0.02em");"
        if let tt = slot.textTransform { s += "text-transform:\(tt);" }
        s += "white-space:pre-line;"

        return "<div style=\"\(s)\">\(display)</div>"
    }

    // MARK: - Device

    private static func renderDevice(_ slot: TemplateDeviceSlot, lit: Bool, screenshotFile: String?) -> String {
        let w = fmt(slot.scale * 100)
        let cx = fmt(slot.x * 100)
        let cy = fmt(slot.y * 100)
        let rot = slot.rotation.map { "rotate(\($0)deg)" } ?? ""
        let transform = "translateX(-50%) \(rot)"
        let z = slot.zIndex.map { "z-index:\($0);" } ?? ""

        var html = "<div style=\"position:absolute;left:\(cx)%;top:\(cy)%;width:\(w)%;transform:\(transform);\(z)\">"

        if let file = screenshotFile {
            html += "<img src=\"\(file)\" style=\"width:100%;display:block;filter:drop-shadow(0 8px 24px rgba(0,0,0,0.3))\" alt=\"\">"
        } else {
            html += renderWireframePhone(lit: lit)
        }

        html += "</div>"
        return html
    }

    // MARK: - Wireframe Phone

    private static func renderWireframePhone(lit: Bool) -> String {
        let scr = lit ? "rgba(255,255,255,0.65)" : "rgba(255,255,255,0.06)"
        let ui = lit ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.06)"
        let ui2 = lit ? "rgba(0,0,0,0.10)" : "rgba(255,255,255,0.09)"
        let uitx = lit ? "rgba(0,0,0,0.30)" : "rgba(255,255,255,0.25)"
        let shadow = lit ? "0.12" : "0.35"
        let frameBg = lit ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.08)"
        let frameBorder = lit ? "rgba(0,0,0,0.12)" : "rgba(255,255,255,0.15)"

        // Real iPhone frame overlay or CSS fallback
        let frameOverlay: String
        let outerStyle: String
        if let dataURL = phoneFrameDataURL {
            frameOverlay = "<img src=\"\(dataURL)\" style=\"position:absolute;inset:0;width:100%;height:100%;z-index:2;pointer-events:none\" alt=\"\">"
            outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)))"
        } else {
            frameOverlay = ""
            outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)));background:\(frameBg);border-radius:12%/5.5%;border:1.5px solid \(frameBorder);overflow:hidden"
        }

        return """
        <div style="\(outerStyle)">\
        <div style="position:absolute;inset:2.6% 2.2%;background:\(scr);border-radius:8%/4%;overflow:hidden;z-index:1">\
        <div style="padding:5% 5% 0;display:flex;justify-content:space-between">\
        <div style="font-size:max(3.5px,1.6cqi);font-weight:600;color:\(uitx);font-family:system-ui">9:41</div>\
        <div style="display:flex;gap:1px;align-items:center">\
        <div style="width:max(3px,1.2cqi);height:max(3px,1.2cqi);border-radius:50%;background:\(uitx)"></div>\
        <div style="width:max(5px,2cqi);height:max(3px,1.2cqi);border-radius:1px;background:\(uitx)"></div>\
        </div></div>\
        <div style="padding:3% 4% 0">\
        <div style="background:\(ui);border-radius:max(3px,1.5cqi);padding:4% 5%;margin-bottom:2%">\
        <div style="display:flex;gap:3%;align-items:center;margin-bottom:3%">\
        <div style="width:max(6px,3cqi);height:max(6px,3cqi);border-radius:50%;background:\(ui2)"></div>\
        <div><div style="height:max(1.5px,0.7cqi);width:max(14px,7cqi);background:\(ui2);border-radius:1px;margin-bottom:2px"></div>\
        <div style="height:max(1px,0.5cqi);width:max(9px,4.5cqi);background:\(ui2);border-radius:1px"></div></div></div>\
        <div style="aspect-ratio:16/9;background:\(ui2);border-radius:max(2px,1cqi);margin-bottom:3%"></div>\
        <div style="height:max(1.5px,0.7cqi);width:80%;background:\(ui2);border-radius:1px;margin-bottom:2%"></div>\
        <div style="height:max(1px,0.5cqi);width:55%;background:\(ui2);border-radius:1px"></div></div>\
        <div style="background:\(ui);border-radius:max(3px,1.5cqi);padding:4% 5%;margin-bottom:2%">\
        <div style="display:flex;gap:3%">\
        <div style="flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)"></div>\
        <div style="flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)"></div>\
        <div style="flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)"></div></div></div>\
        <div style="background:\(ui);border-radius:max(3px,1.5cqi);padding:3.5% 5%;margin-bottom:2%;display:flex;align-items:center;gap:3%">\
        <div style="width:max(5px,2.5cqi);height:max(5px,2.5cqi);border-radius:max(1px,0.5cqi);background:\(ui2)"></div>\
        <div style="flex:1"><div style="height:max(1.5px,0.7cqi);width:70%;background:\(ui2);border-radius:1px;margin-bottom:2px"></div>\
        <div style="height:max(1px,0.5cqi);width:45%;background:\(ui2);border-radius:1px"></div></div></div>\
        <div style="background:\(ui);border-radius:max(3px,1.5cqi);padding:3.5% 5%;display:flex;align-items:center;gap:3%">\
        <div style="width:max(5px,2.5cqi);height:max(5px,2.5cqi);border-radius:50%;background:\(ui2)"></div>\
        <div style="flex:1"><div style="height:max(1.5px,0.7cqi);width:50%;background:\(ui2);border-radius:1px"></div></div></div>\
        </div>\
        <div style="position:absolute;bottom:1.2%;left:30%;right:30%;height:max(1.5px,0.6cqi);background:\(uitx);border-radius:4px"></div>\
        </div>\(frameOverlay)</div>
        """
    }

    private static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

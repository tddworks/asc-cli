import Foundation

/// The local images a composed screenshot page points at, inlined as data URLs
/// so a renderer that loads the page from a string can still draw them.
struct LocalImages {
    let workingDirectory: String
    /// The bytes of the file at a path, or `nil` when there is none.
    let contents: (String) -> Data?

    /// `html` with every local `src="….png|jpg|jpeg|gif|webp"` replaced by its data URL.
    /// Remote images, data URLs and images that can't be found stay as they are.
    func inline(into html: String) -> String {
        let pattern = #"src="([^"]+\.(?:png|jpg|jpeg|gif|webp))""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }
        let page = html as NSString
        var result = html
        // In reverse, so each replacement leaves the earlier ranges where they were.
        for match in regex.matches(in: html, range: NSRange(location: 0, length: page.length)).reversed() {
            let src = page.substring(with: match.range(at: 1))
            guard let (path, data) = file(for: src) else { continue }
            let dataURL = "data:\(Self.mimeType(of: path));base64,\(data.base64EncodedString())"
            result = (result as NSString).replacingCharacters(in: match.range(at: 0), with: "src=\"\(dataURL)\"")
        }
        return result
    }

    /// The file a `src` names and its bytes, or `nil` for a data URL, a remote
    /// image or a file that isn't there.
    private func file(for src: String) -> (path: String, data: Data)? {
        if src.hasPrefix("data:") { return nil }
        if src.hasPrefix("http") {
            // The web server's file URL points back at a file under the working directory.
            guard src.contains("/api/files/read?path="),
                  let path = URLComponents(string: src)?.queryItems?.first(where: { $0.name == "path" })?.value
            else { return nil }
            let local = workingDirectory + "/" + path
            return contents(local).map { (local, $0) }
        }
        let candidates = [
            src.hasPrefix("/") ? src : workingDirectory + "/" + src,
            workingDirectory + "/.asc/app-shots/" + src,
        ]
        for candidate in candidates {
            if let data = contents(candidate) { return (candidate, data) }
        }
        return nil
    }

    private static func mimeType(of path: String) -> String {
        switch (path as NSString).pathExtension.lowercased() {
        case "png": "image/png"
        case "jpg", "jpeg": "image/jpeg"
        case let ext: "image/\(ext)"
        }
    }
}

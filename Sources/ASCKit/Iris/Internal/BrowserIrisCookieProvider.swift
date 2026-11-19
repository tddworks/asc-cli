import Foundation

/// Resolves iris session cookies from the environment or a browser.
///
/// Resolution order:
/// 1. `ASC_IRIS_COOKIES` environment variable (for CI/CD), when not blank
/// 2. The first browser signed in to App Store Connect (holding `myacinfo`)
public struct BrowserIrisCookieProvider: IrisCookieProvider {
    /// `myacinfo` is set on .apple.com; the others (itctx, dqsid, wosid) on appstoreconnect.apple.com.
    static let domains = ["apple.com", "appstoreconnect.apple.com"]
    /// The cookies the iris API reads.
    static let irisCookieNames: Set<String> = [
        "myacinfo", "itctx", "itcdq", "dqsid", "wosid", "woinst", "dssf", "dssid2", "dc",
    ]

    private let environment: [String: String]
    private let browsers: any BrowserCookieStores

    public init() {
        self.init(environment: ProcessInfo.processInfo.environment, browsers: SweetCookieKitStores())
    }

    init(environment: [String: String], browsers: any BrowserCookieStores) {
        self.environment = environment
        self.browsers = browsers
    }

    public func resolveSession() throws -> IrisSession {
        IrisSession(cookies: try resolve().cookies)
    }

    public func resolveStatus() throws -> IrisStatus {
        let (cookies, source) = try resolve()
        return IrisStatus(source: source, cookieCount: cookies.components(separatedBy: "; ").count)
    }

    private func resolve() throws -> (cookies: String, source: IrisCookieSource) {
        if let fromEnvironment = environment["ASC_IRIS_COOKIES"],
           !fromEnvironment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (fromEnvironment, .environment)
        }
        for cookies in browsers.cookiesPerBrowser(domains: Self.domains) {
            if let header = Self.irisCookieHeader(from: cookies) {
                return (header, .browser)
            }
        }
        throw IrisCookieError.noCookiesFound
    }

    /// The iris cookies as a `cookie` header, or `nil` when the browser isn't
    /// signed in (no `myacinfo`). A later cookie of the same name wins.
    private static func irisCookieHeader(from cookies: [BrowserCookie]) -> String? {
        var byName: [String: String] = [:]
        for cookie in cookies where irisCookieNames.contains(cookie.name) {
            byName[cookie.name] = cookie.value
        }
        guard byName["myacinfo"] != nil else { return nil }
        return byName.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    }
}

/// Errors specific to iris cookie resolution.
public enum IrisCookieError: LocalizedError {
    case noCookiesFound

    public var errorDescription: String? {
        switch self {
        case .noCookiesFound:
            "No App Store Connect cookies found. Log in to appstoreconnect.apple.com in your browser, or set ASC_IRIS_COOKIES environment variable."
        }
    }
}

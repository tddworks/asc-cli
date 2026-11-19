import Mockable

/// One cookie a browser holds.
struct BrowserCookie: Equatable, Sendable {
    let name: String
    let value: String
}

/// The browsers' cookie stores on this Mac.
@Mockable
protocol BrowserCookieStores: Sendable {
    /// For each browser, in the order to try them, the unexpired cookies it holds
    /// for any of `domains` (suffix match). A browser that can't be read gives none.
    func cookiesPerBrowser(domains: [String]) -> [[BrowserCookie]]
}

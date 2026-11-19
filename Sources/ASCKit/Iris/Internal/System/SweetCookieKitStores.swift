import SweetCookieKit

/// Reads every browser's cookie store through SweetCookieKit. Only the store
/// reads live here; which cookies count is `BrowserIrisCookieProvider`'s.
struct SweetCookieKitStores: BrowserCookieStores {
    func cookiesPerBrowser(domains: [String]) -> [[BrowserCookie]] {
        let client = BrowserCookieClient()
        return Browser.allCases.map { browser in
            domains.flatMap { domain -> [BrowserCookie] in
                let query = BrowserCookieQuery(domains: [domain], domainMatch: .suffix, includeExpired: false)
                let stores = (try? client.records(matching: query, in: browser)) ?? []
                return stores.flatMap { store in store.records.map { BrowserCookie(name: $0.name, value: $0.value) } }
            }
        }
    }
}

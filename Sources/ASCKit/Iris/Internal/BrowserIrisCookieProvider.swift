import Foundation
import SweetCookieKit

/// Resolves iris session cookies from browser cookie stores or environment.
///
/// Resolution order:
/// 1. `ASC_IRIS_COOKIES` environment variable (for CI/CD)
/// 2. Browser cookies from Chrome/Safari/Firefox (via SweetCookieKit)
public struct BrowserIrisCookieProvider: IrisCookieProvider {
    public init() {}

    public func resolveSession() throws -> IrisSession {
        let (cookies, _) = try resolve()
        return IrisSession(cookies: cookies)
    }

    public func resolveStatus() throws -> IrisStatus {
        let (cookies, source) = try resolve()
        let count = cookies.components(separatedBy: "; ").count
        return IrisStatus(source: source, cookieCount: count)
    }

    private func resolve() throws -> (String, IrisCookieSource) {
        // 1. Check environment variable
        if let envCookies = ProcessInfo.processInfo.environment["ASC_IRIS_COOKIES"],
           !envCookies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return (envCookies, .environment)
        }

        // 2. Try extracting from browser cookies
        if let browserCookies = fetchFromBrowser() {
            return (browserCookies, .browser)
        }

        throw IrisCookieError.noCookiesFound
    }

    private func fetchFromBrowser() -> String? {
        let cookieClient = BrowserCookieClient()

        // myacinfo is set on .apple.com (parent domain)
        // other cookies (itctx, dqsid, wosid) are on appstoreconnect.apple.com
        let queries: [BrowserCookieQuery] = [
            BrowserCookieQuery(
                domains: ["apple.com"],
                domainMatch: .suffix,
                includeExpired: false
            ),
            BrowserCookieQuery(
                domains: ["appstoreconnect.apple.com"],
                domainMatch: .suffix,
                includeExpired: false
            ),
        ]

        // Cookie names relevant for iris API
        let wantedNames: Set<String> = [
            "myacinfo", "itctx", "itcdq", "dqsid", "wosid", "woinst",
            "dssf", "dssid2", "dc",
        ]

        for browser in Browser.allCases {
            var cookieMap: [String: String] = [:]

            for query in queries {
                do {
                    let storeRecords = try cookieClient.records(matching: query, in: browser)
                    for storeRecord in storeRecords {
                        for record in storeRecord.records where wantedNames.contains(record.name) {
                            cookieMap[record.name] = record.value
                        }
                    }
                } catch {
                    continue
                }
            }

            // myacinfo is the essential auth cookie
            if cookieMap["myacinfo"] != nil {
                let cookieString = cookieMap.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
                return cookieString
            }
        }
        return nil
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

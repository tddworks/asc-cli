import Foundation
import Mockable
import Testing
@testable import ASCKit

@Suite
struct BrowserIrisCookieProviderTests {
    private func browsers(_ perBrowser: [[BrowserCookie]]) -> MockBrowserCookieStores {
        let stores = MockBrowserCookieStores()
        given(stores).cookiesPerBrowser(domains: .any).willReturn(perBrowser)
        return stores
    }

    @Test func `should use the cookies from ASC_IRIS_COOKIES before any browser`() throws {
        let provider = BrowserIrisCookieProvider(
            environment: ["ASC_IRIS_COOKIES": "myacinfo=from-env"],
            browsers: browsers([[BrowserCookie(name: "myacinfo", value: "from-browser")]])
        )

        #expect(try provider.resolveSession() == IrisSession(cookies: "myacinfo=from-env"))
        #expect(try provider.resolveStatus() == IrisStatus(source: .environment, cookieCount: 1))
    }

    @Test func `should ignore ASC_IRIS_COOKIES when it is blank`() throws {
        let provider = BrowserIrisCookieProvider(
            environment: ["ASC_IRIS_COOKIES": "  "],
            browsers: browsers([[BrowserCookie(name: "myacinfo", value: "a")]])
        )

        #expect(try provider.resolveSession() == IrisSession(cookies: "myacinfo=a"))
    }

    @Test func `should take the iris cookies from the first browser signed in to App Store Connect`() throws {
        let provider = BrowserIrisCookieProvider(
            environment: [:],
            browsers: browsers([
                [BrowserCookie(name: "dc", value: "not-signed-in")],
                [
                    BrowserCookie(name: "myacinfo", value: "a"),
                    BrowserCookie(name: "unrelated", value: "x"),
                    BrowserCookie(name: "itctx", value: "b"),
                ],
                [BrowserCookie(name: "myacinfo", value: "later-browser")],
            ])
        )

        #expect(try provider.resolveSession() == IrisSession(cookies: "itctx=b; myacinfo=a"))
        #expect(try provider.resolveStatus() == IrisStatus(source: .browser, cookieCount: 2))
    }

    @Test func `should report no cookies when no browser is signed in to App Store Connect`() {
        let provider = BrowserIrisCookieProvider(
            environment: [:],
            browsers: browsers([[BrowserCookie(name: "itctx", value: "b")], []])
        )

        do {
            _ = try provider.resolveSession()
            Issue.record("expected no cookies")
        } catch IrisCookieError.noCookiesFound {
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}

import Domain
import Foundation
import Mockable
import Testing
@testable import Infrastructure

@Suite
struct CompositeIrisCookieProviderTests {

    @Test func `resolveSession returns the first provider's session when it succeeds`() throws {
        let primary = MockIrisCookieProvider()
        given(primary).resolveSession().willReturn(IrisSession(cookies: "primary=1"))
        let fallback = MockIrisCookieProvider()
        given(fallback).resolveSession().willReturn(IrisSession(cookies: "fallback=1"))

        let composite = CompositeIrisCookieProvider(providers: [primary, fallback])
        let result = try composite.resolveSession()
        #expect(result.cookies == "primary=1")
        verify(fallback).resolveSession().called(0)
    }

    @Test func `resolveSession falls through to the next provider when the first throws`() throws {
        let primary = MockIrisCookieProvider()
        given(primary).resolveSession().willThrow(IrisCookieError.noCookiesFound)
        let fallback = MockIrisCookieProvider()
        given(fallback).resolveSession().willReturn(IrisSession(cookies: "fallback=1"))

        let composite = CompositeIrisCookieProvider(providers: [primary, fallback])
        let result = try composite.resolveSession()
        #expect(result.cookies == "fallback=1")
    }

    @Test func `resolveSession surfaces the last error when every provider fails`() {
        struct Sentinel: Error, Equatable {}
        let primary = MockIrisCookieProvider()
        given(primary).resolveSession().willThrow(IrisCookieError.noCookiesFound)
        let last = MockIrisCookieProvider()
        given(last).resolveSession().willThrow(Sentinel())

        let composite = CompositeIrisCookieProvider(providers: [primary, last])
        #expect(throws: Sentinel.self) {
            _ = try composite.resolveSession()
        }
    }

    @Test func `resolveStatus returns the first provider that succeeds`() throws {
        let primary = MockIrisCookieProvider()
        given(primary).resolveStatus().willThrow(IrisCookieError.noCookiesFound)
        let fallback = MockIrisCookieProvider()
        given(fallback).resolveStatus().willReturn(IrisStatus(source: .browser, cookieCount: 3))

        let composite = CompositeIrisCookieProvider(providers: [primary, fallback])
        let status = try composite.resolveStatus()
        #expect(status.source == .browser)
        #expect(status.cookieCount == 3)
    }

    @Test func `resolveSession with empty provider list throws noCookiesFound`() {
        let composite = CompositeIrisCookieProvider(providers: [])
        #expect(throws: IrisCookieError.noCookiesFound) {
            _ = try composite.resolveSession()
        }
    }
}

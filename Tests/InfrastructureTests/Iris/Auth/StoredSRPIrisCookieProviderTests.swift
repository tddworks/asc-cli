import Domain
import Foundation
import Mockable
import Testing
@testable import Infrastructure

@Suite
struct StoredSRPIrisCookieProviderTests {

    private func session(
        cookies: String = "myacinfo=1; itctx=2",
        expiresAt: Date
    ) -> IrisAuthSession {
        IrisAuthSession(
            cookies: cookies,
            scnt: "scnt",
            serviceKey: "key",
            appleIDSessionID: "sid",
            providerID: 1,
            teamId: "T",
            userEmail: "u@x.com",
            expiresAt: expiresAt
        )
    }

    @Test func `resolveSession returns cookies from the persisted session when it has not expired`() throws {
        let storage = MockIrisSessionRepository()
        given(storage).current().willReturn(
            session(cookies: "myacinfo=1; itctx=2", expiresAt: Date().addingTimeInterval(3600))
        )
        let provider = StoredSRPIrisCookieProvider(sessionRepository: storage)
        let result = try provider.resolveSession()
        #expect(result.cookies == "myacinfo=1; itctx=2")
    }

    @Test func `resolveSession throws noCookiesFound when storage is empty`() {
        let storage = MockIrisSessionRepository()
        given(storage).current().willReturn(nil)
        let provider = StoredSRPIrisCookieProvider(sessionRepository: storage)
        #expect(throws: IrisCookieError.noCookiesFound) {
            _ = try provider.resolveSession()
        }
    }

    @Test func `resolveSession throws when the persisted session has expired`() {
        let storage = MockIrisSessionRepository()
        given(storage).current().willReturn(
            session(expiresAt: Date(timeIntervalSinceNow: -60))
        )
        let provider = StoredSRPIrisCookieProvider(sessionRepository: storage)
        #expect(throws: IrisCookieError.noCookiesFound) {
            _ = try provider.resolveSession()
        }
    }

    @Test func `resolveStatus reports srpLogin source and counts cookies`() throws {
        let storage = MockIrisSessionRepository()
        given(storage).current().willReturn(
            session(
                cookies: "myacinfo=1; itctx=2; dqsid=3",
                expiresAt: Date().addingTimeInterval(3600)
            )
        )
        let provider = StoredSRPIrisCookieProvider(sessionRepository: storage)
        let status = try provider.resolveStatus()
        #expect(status.source == .srpLogin)
        #expect(status.cookieCount == 3)
    }
}

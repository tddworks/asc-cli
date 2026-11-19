import Testing
@testable import ASCKit

@Suite
struct IrisSessionTests {

    @Test func `session holds cookie string`() {
        let session = IrisSession(cookies: "myacinfo=abc; itctx=xyz")
        #expect(session.cookies == "myacinfo=abc; itctx=xyz")
    }

    @Test func `sessions with same cookies are equal`() {
        let a = IrisSession(cookies: "myacinfo=abc")
        let b = IrisSession(cookies: "myacinfo=abc")
        #expect(a == b)
    }
}
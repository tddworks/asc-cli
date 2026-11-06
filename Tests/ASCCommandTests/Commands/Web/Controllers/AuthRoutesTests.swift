import Foundation
import Hummingbird
import HummingbirdTesting
import HummingbirdWebSocket
import Mockable
import NIOCore
import Testing
@testable import ASCCommand
@testable import Domain
@testable import Infrastructure

@Suite
struct AuthRoutesTests {

    @Test func `should save an individual key over REST when no issuer ID is given`() async throws {
        let storage = MockAuthStorage()
        given(storage).save(.any, name: .value("me")).willReturn()
        given(storage).setActive(name: .value("me")).willReturn()
        let router = Router(context: BasicWebSocketRequestContext.self)
        AuthController(storage: storage).addRoutes(to: router.group("/api/v1"))

        let body = #"{"keyId":"KEY123","privateKeyPEM":"pem","name":"me"}"#
        let response = try await Application(router: router).test(.router) { client in
            try await client.execute(
                uri: "/api/v1/auth/accounts",
                method: .post,
                body: ByteBuffer(string: body)
            ) { String(buffer: $0.body) }
        }

        let json = try #require(try JSONSerialization.jsonObject(with: Data(response.utf8)) as? [String: Any])
        let status = try #require((json["data"] as? [[String: Any]])?.first)
        #expect(status["keyID"] as? String == "KEY123")
        #expect(status["name"] as? String == "me")
        #expect(status["issuerID"] == nil)
    }
}

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

    @Test func `should reject an issuer ID that is not a string and save no account`() async throws {
        let storage = FileAuthStorage(fileURL: FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json"))
        let router = Router(context: BasicWebSocketRequestContext.self)
        AuthController(storage: storage).addRoutes(to: router.group("/api/v1"))

        let body = #"{"keyId":"KEY123","issuerId":12345,"privateKeyPEM":"pem","name":"me"}"#
        let (status, response) = try await Application(router: router).test(.router) { client in
            try await client.execute(
                uri: "/api/v1/auth/accounts",
                method: .post,
                body: ByteBuffer(string: body)
            ) { ($0.status, String(buffer: $0.body)) }
        }

        #expect(status == .badRequest)
        #expect(response == #"{"error":"issuerId must be a string"}"#)
        #expect(try storage.loadAll() == [])
    }
}

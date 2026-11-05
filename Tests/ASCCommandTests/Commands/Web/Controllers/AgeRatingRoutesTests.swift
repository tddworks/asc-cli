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
struct AgeRatingRoutesTests {

    @Test func `should save the social media answers over REST`() async throws {
        let repo = MockAgeRatingDeclarationRepository()
        given(repo).updateDeclaration(id: .value("decl-1"), update: .any).willProduce { id, update in
            AgeRatingDeclaration(
                id: id,
                appInfoId: "info-1",
                isSocialMedia: update.isSocialMedia,
                isSocialMediaAgeRestricted: update.isSocialMediaAgeRestricted,
                developerAgeRatingInfoUrl: update.developerAgeRatingInfoUrl
            )
        }
        let router = Router(context: BasicWebSocketRequestContext.self)
        AgeRatingController(repo: repo).addRoutes(to: router.group("/api/v1"))

        let body = #"{"isSocialMedia":false,"isSocialMediaAgeRestricted":true,"developerAgeRatingInfoUrl":"https://example.com/age"}"#
        let response = try await Application(router: router).test(.router) { client in
            try await client.execute(
                uri: "/api/v1/age-rating/decl-1",
                method: .patch,
                body: ByteBuffer(string: body)
            ) { String(buffer: $0.body) }
        }

        let json = try #require(try JSONSerialization.jsonObject(with: Data(response.utf8)) as? [String: Any])
        let declaration = try #require((json["data"] as? [[String: Any]])?.first)
        #expect(declaration["isSocialMedia"] as? Bool == false)
        #expect(declaration["isSocialMediaAgeRestricted"] as? Bool == true)
        #expect(declaration["developerAgeRatingInfoUrl"] as? String == "https://example.com/age")
    }
}

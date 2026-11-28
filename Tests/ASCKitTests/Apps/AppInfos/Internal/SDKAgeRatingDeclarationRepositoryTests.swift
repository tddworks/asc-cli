@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import ASCKit

@Suite
struct SDKAgeRatingDeclarationRepositoryTests {

    // MARK: - getDeclaration

    @Test func `getDeclaration injects appInfoId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(type: .ageRatingDeclarations, id: "decl-1"),
            links: .init(this: "")
        ))

        let repo = SDKAgeRatingDeclarationRepository(client: stub)
        let result = try await repo.getDeclaration(appInfoId: "info-42")

        #expect(result.id == "decl-1")
        #expect(result.appInfoId == "info-42")
    }

    @Test func `getDeclaration maps boolean attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(
                type: .ageRatingDeclarations,
                id: "decl-1",
                attributes: .init(isAdvertising: true, isGambling: false, isLootBox: true)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAgeRatingDeclarationRepository(client: stub)
        let result = try await repo.getDeclaration(appInfoId: "info-1")

        #expect(result.isAdvertising == true)
        #expect(result.isGambling == false)
        #expect(result.isLootBox == true)
    }

    @Test func `getDeclaration maps intensity attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(
                type: .ageRatingDeclarations,
                id: "decl-1",
                attributes: .init(
                    profanityOrCrudeHumor: .infrequentOrMild,
                    violenceRealistic: .frequentOrIntense
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKAgeRatingDeclarationRepository(client: stub)
        let result = try await repo.getDeclaration(appInfoId: "info-1")

        #expect(result.violenceRealistic == .frequentOrIntense)
        #expect(result.profanityOrCrudeHumor == .infrequentOrMild)
    }

    @Test func `getDeclaration maps kidsAgeBand`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(
                type: .ageRatingDeclarations,
                id: "decl-1",
                attributes: .init(kidsAgeBand: .nineToEleven)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAgeRatingDeclarationRepository(client: stub)
        let result = try await repo.getDeclaration(appInfoId: "info-1")

        #expect(result.kidsAgeBand == .nineToEleven)
    }

    @Test func `getDeclaration maps ageRatingOverrideV2`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(
                type: .ageRatingDeclarations,
                id: "decl-1",
                attributes: .init(ageRatingOverrideV2: .thirteenPlus)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAgeRatingDeclarationRepository(client: stub)
        let result = try await repo.getDeclaration(appInfoId: "info-1")

        #expect(result.ageRatingOverride == .thirteenPlus)
    }

    @Test func `should show a Korea override of twelve plus when App Store Connect sends it`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(
                type: .ageRatingDeclarations,
                id: "decl-1",
                attributes: .init(koreaAgeRatingOverride: .twelvePlus)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAgeRatingDeclarationRepository(client: stub)
        let result = try await repo.getDeclaration(appInfoId: "info-1")

        #expect(result.koreaAgeRatingOverride == .twelvePlus)
    }

    @Test func `should show a Korea override of all ages when App Store Connect sends it`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(
                type: .ageRatingDeclarations,
                id: "decl-1",
                attributes: .init(koreaAgeRatingOverride: .all)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAgeRatingDeclarationRepository(client: stub)
        let result = try await repo.getDeclaration(appInfoId: "info-1")

        #expect(result.koreaAgeRatingOverride == .all)
    }

    @Test func `should show Korea's GRAC classification number when App Store Connect has one`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(
                type: .ageRatingDeclarations,
                id: "decl-1",
                attributes: .init(gracRatingClassificationNumber: "CC-OL-000000-000")
            ),
            links: .init(this: "")
        ))

        let repo = SDKAgeRatingDeclarationRepository(client: stub)
        let result = try await repo.getDeclaration(appInfoId: "info-1")

        #expect(result.gracRatingClassificationNumber == "CC-OL-000000-000")
    }

    // MARK: - updateDeclaration

    @Test func `updateDeclaration returns mapped declaration`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(
                type: .ageRatingDeclarations,
                id: "decl-1",
                attributes: .init(isAdvertising: false, violenceRealistic: .frequentOrIntense)
            ),
            links: .init(this: "")
        ))

        var update = ASCKit.AgeRatingDeclarationUpdate()
        update.isAdvertising = false
        update.violenceRealistic = .frequentOrIntense

        let repo = SDKAgeRatingDeclarationRepository(client: stub)
        let result = try await repo.updateDeclaration(id: "decl-1", update: update)

        #expect(result.id == "decl-1")
        #expect(result.isAdvertising == false)
        #expect(result.violenceRealistic == .frequentOrIntense)
    }

    // MARK: - Social media and developer info answers

    @Test func `should show the social media answers App Store Connect has`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(
                type: .ageRatingDeclarations,
                id: "decl-1",
                attributes: .init(
                    isSocialMedia: false,
                    isSocialMediaAgeRestricted: true,
                    developerAgeRatingInfoURL: URL(string: "https://example.com/age")
                )
            ),
            links: .init(this: "")
        ))

        let result = try await SDKAgeRatingDeclarationRepository(client: stub).getDeclaration(appInfoId: "info-1")

        #expect(result.isSocialMedia == false)
        #expect(result.isSocialMediaAgeRestricted == true)
        #expect(result.developerAgeRatingInfoUrl == "https://example.com/age")
    }

    @Test func `should leave the social media answers empty when App Store Connect has none`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(type: .ageRatingDeclarations, id: "decl-1", attributes: .init()),
            links: .init(this: "")
        ))

        let result = try await SDKAgeRatingDeclarationRepository(client: stub).getDeclaration(appInfoId: "info-1")

        #expect(result.isSocialMedia == nil)
        #expect(result.isSocialMediaAgeRestricted == nil)
        #expect(result.developerAgeRatingInfoUrl == nil)
    }

    @Test func `should send the social media answers to App Store Connect`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(type: .ageRatingDeclarations, id: "decl-1"),
            links: .init(this: "")
        ))
        var update = ASCKit.AgeRatingDeclarationUpdate()
        update.isSocialMedia = false
        update.isSocialMediaAgeRestricted = true
        update.developerAgeRatingInfoUrl = "https://example.com/age"

        _ = try await SDKAgeRatingDeclarationRepository(client: stub).updateDeclaration(id: "decl-1", update: update)

        let body = try #require(stub.requests.first?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
        let attributes = try #require((json["data"] as? [String: Any])?["attributes"] as? [String: Any])
        #expect(attributes["socialMedia"] as? Bool == false)
        #expect(attributes["socialMediaAgeRestricted"] as? Bool == true)
        #expect(attributes["developerAgeRatingInfoUrl"] as? String == "https://example.com/age")
    }

    // MARK: - Questions the SDK doesn't model yet (sharedLocation, datingAndRelationships)

    @Test func `should show the shared location and dating answers App Store Connect sends`() async throws {
        let json = #"{"data":{"type":"ageRatingDeclarations","id":"decl-1","attributes":{"socialMedia":false,"sharedLocation":false,"datingAndRelationships":true}},"links":{"self":""}}"#
        let stub = StubAPIClient()
        stub.willReturn(try JSONDecoder().decode(AgeRatingDeclarationDocument.self, from: Data(json.utf8)))

        let result = try await SDKAgeRatingDeclarationRepository(client: stub).getDeclaration(appInfoId: "info-1")

        #expect(result.isSocialMedia == false)
        #expect(result.isSharedLocation == false)
        #expect(result.isDatingAndRelationships == true)
    }

    @Test func `should send the shared location and dating answers to App Store Connect`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(type: .ageRatingDeclarations, id: "decl-1"),
            links: .init(this: "")
        ))
        var update = ASCKit.AgeRatingDeclarationUpdate()
        update.isSocialMedia = false
        update.isSharedLocation = false
        update.isDatingAndRelationships = true

        _ = try await SDKAgeRatingDeclarationRepository(client: stub).updateDeclaration(id: "decl-1", update: update)

        let body = try #require(stub.requests.first?.body)
        #expect(body == #"{"data":{"attributes":{"datingAndRelationships":true,"developerAgeRatingInfoUrl":null,"kidsAgeBand":null,"sharedLocation":false,"socialMedia":false},"id":"decl-1","type":"ageRatingDeclarations"}}"#)
    }
}

private extension StubAPIClient {
    /// Fixtures are written with the SDK's response type; the repository decodes its own
    /// document so it can also read the attributes the SDK lacks.
    func willReturn(_ response: AgeRatingDeclarationResponse) {
        willReturn(AgeRatingDeclarationDocument(response))
    }
}

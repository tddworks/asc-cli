@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKAppClipRepositoryListAppClipsTests {

    @Test func `listAppClips injects appId into each clip`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppClipsResponse(
            data: [
                AppClip(type: .appClips, id: "clip-1"),
                AppClip(type: .appClips, id: "clip-2"),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppClips(client: stub)
        let result = try await repo.listAppClips(appId: "app-99")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.appId == "app-99" })
    }

    @Test func `listAppClips maps bundleId from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppClipsResponse(
            data: [
                AppClip(type: .appClips, id: "clip-1", attributes: .init(bundleID: "com.example.clip")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppClips(client: stub)
        let result = try await repo.listAppClips(appId: "app-1")

        #expect(result[0].bundleId == "com.example.clip")
    }

    @Test func `listAppClips maps nil bundleId when attributes absent`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppClipsResponse(
            data: [AppClip(type: .appClips, id: "clip-1")],
            links: .init(this: "")
        ))

        let repo = SDKAppClips(client: stub)
        let result = try await repo.listAppClips(appId: "app-1")

        #expect(result[0].bundleId == nil)
    }
}

@Suite
struct SDKAppClipRepositoryListExperiencesTests {

    @Test func `listExperiences injects appClipId into each experience`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppClipDefaultExperiencesResponse(
            data: [
                AppClipDefaultExperience(type: .appClipDefaultExperiences, id: "exp-1"),
                AppClipDefaultExperience(type: .appClipDefaultExperiences, id: "exp-2"),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppClips(client: stub)
        let result = try await repo.listExperiences(appClipId: "clip-42")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.appClipId == "clip-42" })
    }

    @Test func `listExperiences maps action from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppClipDefaultExperiencesResponse(
            data: [
                AppClipDefaultExperience(type: .appClipDefaultExperiences, id: "exp-1", attributes: .init(action: .open)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppClips(client: stub)
        let result = try await repo.listExperiences(appClipId: "clip-1")

        #expect(result[0].action == .open)
    }
}

@Suite
struct SDKAppClipRepositoryCreateExperienceTests {

    @Test func `createExperience injects appClipId from request parameter`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppClipDefaultExperienceResponse(
            data: AppClipDefaultExperience(type: .appClipDefaultExperiences, id: "exp-new", attributes: .init(action: .view)),
            links: .init(this: "")
        ))

        let repo = SDKAppClips(client: stub)
        let result = try await repo.createExperience(appClipId: "clip-42", action: .view)

        #expect(result.id == "exp-new")
        #expect(result.appClipId == "clip-42")
        #expect(result.action == .view)
    }
}

@Suite
struct SDKAppClipRepositoryListLocalizationsTests {

    @Test func `listLocalizations injects experienceId into each localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppClipDefaultExperienceLocalizationsResponse(
            data: [
                AppClipDefaultExperienceLocalization(type: .appClipDefaultExperienceLocalizations, id: "loc-1", attributes: .init(locale: "en-US")),
                AppClipDefaultExperienceLocalization(type: .appClipDefaultExperienceLocalizations, id: "loc-2", attributes: .init(locale: "fr-FR")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppClips(client: stub)
        let result = try await repo.listLocalizations(experienceId: "exp-42")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.experienceId == "exp-42" })
    }

    @Test func `listLocalizations maps locale and subtitle from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppClipDefaultExperienceLocalizationsResponse(
            data: [
                AppClipDefaultExperienceLocalization(
                    type: .appClipDefaultExperienceLocalizations,
                    id: "loc-1",
                    attributes: .init(locale: "fr-FR", subtitle: "Accès rapide")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppClips(client: stub)
        let result = try await repo.listLocalizations(experienceId: "exp-1")

        #expect(result[0].locale == "fr-FR")
        #expect(result[0].subtitle == "Accès rapide")
    }
}

@Suite
struct SDKAppClipRepositoryCreateLocalizationTests {

    @Test func `createLocalization injects experienceId from request parameter`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppClipDefaultExperienceLocalizationResponse(
            data: AppClipDefaultExperienceLocalization(
                type: .appClipDefaultExperienceLocalizations,
                id: "loc-new",
                attributes: .init(locale: "en-US", subtitle: "Quick access")
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppClips(client: stub)
        let result = try await repo.createLocalization(experienceId: "exp-42", locale: "en-US", subtitle: "Quick access")

        #expect(result.id == "loc-new")
        #expect(result.experienceId == "exp-42")
        #expect(result.locale == "en-US")
        #expect(result.subtitle == "Quick access")
    }
}

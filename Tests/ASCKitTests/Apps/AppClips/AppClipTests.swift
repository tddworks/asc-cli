import Testing
@testable import ASCKit

@Suite
struct AppClipTests {

    @Test func `app clip carries appId`() {
        let clip = MockRepositoryFactory.makeAppClip(id: "clip-1", appId: "app-99")
        #expect(clip.appId == "app-99")
    }

    @Test func `app clip carries bundleId`() {
        let clip = MockRepositoryFactory.makeAppClip(id: "clip-1", appId: "app-1", bundleId: "com.example.clip")
        #expect(clip.bundleId == "com.example.clip")
    }

    @Test func `app clip affordances include listExperiences`() {
        let clip = MockRepositoryFactory.makeAppClip(id: "clip-1", appId: "app-1")
        #expect(clip.affordances["listExperiences"] == "asc app-clip-experiences list --app-clip-id clip-1")
    }

    @Test func `app clip affordances include listAppClips`() {
        let clip = MockRepositoryFactory.makeAppClip(id: "clip-1", appId: "app-1")
        #expect(clip.affordances["listAppClips"] == "asc app-clips list --app-id app-1")
    }
}

@Suite
struct AppClipDefaultExperienceTests {

    @Test func `experience carries appClipId`() {
        let exp = MockRepositoryFactory.makeAppClipDefaultExperience(id: "exp-1", appClipId: "clip-1")
        #expect(exp.appClipId == "clip-1")
    }

    @Test func `experience carries action`() {
        let exp = MockRepositoryFactory.makeAppClipDefaultExperience(id: "exp-1", appClipId: "clip-1", action: .open)
        #expect(exp.action == .open)
    }

    @Test func `experience affordances include listLocalizations`() {
        let exp = MockRepositoryFactory.makeAppClipDefaultExperience(id: "exp-1", appClipId: "clip-1")
        #expect(exp.affordances["listLocalizations"] == "asc app-clip-experience-localizations list --experience-id exp-1")
    }

    @Test func `experience affordances include delete`() {
        let exp = MockRepositoryFactory.makeAppClipDefaultExperience(id: "exp-1", appClipId: "clip-1")
        #expect(exp.affordances["delete"] == "asc app-clip-experiences delete --experience-id exp-1")
    }

    @Test func `experience affordances include listExperiences`() {
        let exp = MockRepositoryFactory.makeAppClipDefaultExperience(id: "exp-1", appClipId: "clip-1")
        #expect(exp.affordances["listExperiences"] == "asc app-clip-experiences list --app-clip-id clip-1")
    }
}

@Suite
struct AppClipActionTests {

    @Test func `open action has OPEN raw value`() {
        #expect(AppClipAction.open.rawValue == "OPEN")
    }

    @Test func `view action has VIEW raw value`() {
        #expect(AppClipAction.view.rawValue == "VIEW")
    }

    @Test func `play action has PLAY raw value`() {
        #expect(AppClipAction.play.rawValue == "PLAY")
    }
}

@Suite
struct AppClipDefaultExperienceLocalizationTests {

    @Test func `localization carries experienceId`() {
        let loc = MockRepositoryFactory.makeAppClipDefaultExperienceLocalization(id: "loc-1", experienceId: "exp-1")
        #expect(loc.experienceId == "exp-1")
    }

    @Test func `localization carries locale`() {
        let loc = MockRepositoryFactory.makeAppClipDefaultExperienceLocalization(id: "loc-1", experienceId: "exp-1", locale: "fr-FR")
        #expect(loc.locale == "fr-FR")
    }

    @Test func `localization carries subtitle`() {
        let loc = MockRepositoryFactory.makeAppClipDefaultExperienceLocalization(id: "loc-1", experienceId: "exp-1", subtitle: "Quick access")
        #expect(loc.subtitle == "Quick access")
    }

    @Test func `localization affordances include delete`() {
        let loc = MockRepositoryFactory.makeAppClipDefaultExperienceLocalization(id: "loc-1", experienceId: "exp-1")
        #expect(loc.affordances["delete"] == "asc app-clip-experience-localizations delete --localization-id loc-1")
    }

    @Test func `localization affordances include listLocalizations`() {
        let loc = MockRepositoryFactory.makeAppClipDefaultExperienceLocalization(id: "loc-1", experienceId: "exp-1")
        #expect(loc.affordances["listLocalizations"] == "asc app-clip-experience-localizations list --experience-id exp-1")
    }
}

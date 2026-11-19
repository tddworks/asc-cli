import Testing
@testable import ASCKit

@Suite
struct ProfileTests {

    @Test func `profile carries bundleIdId as parent`() {
        let profile = MockRepositoryFactory.makeProfile(id: "prof-1", bundleIdId: "bid-99")
        #expect(profile.bundleIdId == "bid-99")
    }

    @Test func `active profile isActive is true`() {
        let profile = MockRepositoryFactory.makeProfile(profileState: .active)
        #expect(profile.isActive == true)
    }

    @Test func `invalid profile isActive is false`() {
        let profile = MockRepositoryFactory.makeProfile(profileState: .invalid)
        #expect(profile.isActive == false)
    }

    @Test func `profile type raw values match asc api`() {
        #expect(ProfileType.iosAppStore.rawValue == "IOS_APP_STORE")
        #expect(ProfileType.macAppStore.rawValue == "MAC_APP_STORE")
        #expect(ProfileType.iosAppDevelopment.rawValue == "IOS_APP_DEVELOPMENT")
        #expect(ProfileType.macCatalystAppStore.rawValue == "MAC_CATALYST_APP_STORE")
    }

    @Test func `profile state raw values match asc api`() {
        #expect(ProfileState.active.rawValue == "ACTIVE")
        #expect(ProfileState.invalid.rawValue == "INVALID")
    }
}

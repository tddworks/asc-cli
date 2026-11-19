import Mockable

@Mockable
public protocol AppClipRepository: Sendable {
    func listAppClips(appId: String) async throws -> [AppClip]
    func listExperiences(appClipId: String) async throws -> [AppClipDefaultExperience]
    func createExperience(appClipId: String, action: AppClipAction?) async throws -> AppClipDefaultExperience
    func deleteExperience(id: String) async throws
    func listLocalizations(experienceId: String) async throws -> [AppClipDefaultExperienceLocalization]
    func createLocalization(experienceId: String, locale: String, subtitle: String?) async throws -> AppClipDefaultExperienceLocalization
    func deleteLocalization(id: String) async throws
}

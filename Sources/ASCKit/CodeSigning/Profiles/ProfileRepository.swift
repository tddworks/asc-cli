import Mockable

@Mockable
public protocol ProfileRepository: Sendable {
    func listProfiles(bundleIdId: String?, profileType: ProfileType?) async throws -> [Profile]
    func createProfile(
        name: String,
        profileType: ProfileType,
        bundleIdId: String,
        certificateIds: [String],
        deviceIds: [String]
    ) async throws -> Profile
    func deleteProfile(id: String) async throws
}

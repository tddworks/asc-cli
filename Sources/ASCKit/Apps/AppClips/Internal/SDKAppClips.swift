@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKAppClips: AppClips, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listAppClips(appId: String) async throws -> [ASCKit.AppClip] {
        let request = APIEndpoint.v1.apps.id(appId).appClips.get()
        let response = try await client.request(request)
        return response.data.map { mapAppClip($0, appId: appId) }
    }

    public func listExperiences(appClipId: String) async throws -> [ASCKit.AppClipDefaultExperience] {
        let request = APIEndpoint.v1.appClips.id(appClipId).appClipDefaultExperiences.get()
        let response = try await client.request(request)
        return response.data.map { mapExperience($0, appClipId: appClipId) }
    }

    public func createExperience(appClipId: String, action: ASCKit.AppClipAction?) async throws -> ASCKit.AppClipDefaultExperience {
        let sdkAction = action.map { mapActionToSDK($0) }
        let body = AppClipDefaultExperienceCreateRequest(
            data: .init(
                type: .appClipDefaultExperiences,
                attributes: .init(action: sdkAction),
                relationships: .init(appClip: .init(data: .init(type: .appClips, id: appClipId)))
            )
        )
        let response = try await client.request(APIEndpoint.v1.appClipDefaultExperiences.post(body))
        return mapExperience(response.data, appClipId: appClipId)
    }

    public func deleteExperience(id: String) async throws {
        try await client.request(APIEndpoint.v1.appClipDefaultExperiences.id(id).delete)
    }

    public func listLocalizations(experienceId: String) async throws -> [ASCKit.AppClipDefaultExperienceLocalization] {
        let request = APIEndpoint.v1.appClipDefaultExperiences.id(experienceId).appClipDefaultExperienceLocalizations.get()
        let response = try await client.request(request)
        return response.data.map { mapLocalization($0, experienceId: experienceId) }
    }

    public func createLocalization(experienceId: String, locale: String, subtitle: String?) async throws -> ASCKit.AppClipDefaultExperienceLocalization {
        let body = AppClipDefaultExperienceLocalizationCreateRequest(
            data: .init(
                type: .appClipDefaultExperienceLocalizations,
                attributes: .init(locale: locale, subtitle: subtitle),
                relationships: .init(appClipDefaultExperience: .init(data: .init(type: .appClipDefaultExperiences, id: experienceId)))
            )
        )
        let response = try await client.request(APIEndpoint.v1.appClipDefaultExperienceLocalizations.post(body))
        return mapLocalization(response.data, experienceId: experienceId)
    }

    public func deleteLocalization(id: String) async throws {
        try await client.request(APIEndpoint.v1.appClipDefaultExperienceLocalizations.id(id).delete)
    }

    // MARK: - Mappers

    private func mapAppClip(
        _ sdkClip: AppStoreConnect_Swift_SDK.AppClip,
        appId: String
    ) -> ASCKit.AppClip {
        ASCKit.AppClip(
            id: sdkClip.id,
            appId: appId,
            bundleId: sdkClip.attributes?.bundleID
        )
    }

    private func mapExperience(
        _ sdkExp: AppStoreConnect_Swift_SDK.AppClipDefaultExperience,
        appClipId: String
    ) -> ASCKit.AppClipDefaultExperience {
        ASCKit.AppClipDefaultExperience(
            id: sdkExp.id,
            appClipId: appClipId,
            action: sdkExp.attributes?.action.map { mapActionFromSDK($0) }
        )
    }

    private func mapLocalization(
        _ sdkLoc: AppStoreConnect_Swift_SDK.AppClipDefaultExperienceLocalization,
        experienceId: String
    ) -> ASCKit.AppClipDefaultExperienceLocalization {
        ASCKit.AppClipDefaultExperienceLocalization(
            id: sdkLoc.id,
            experienceId: experienceId,
            locale: sdkLoc.attributes?.locale ?? "",
            subtitle: sdkLoc.attributes?.subtitle
        )
    }

    private func mapActionFromSDK(_ sdkAction: AppStoreConnect_Swift_SDK.AppClipAction) -> ASCKit.AppClipAction {
        switch sdkAction {
        case .open: return .open
        case .view: return .view
        case .play: return .play
        }
    }

    private func mapActionToSDK(_ action: ASCKit.AppClipAction) -> AppStoreConnect_Swift_SDK.AppClipAction {
        switch action {
        case .open: return .open
        case .view: return .view
        case .play: return .play
        }
    }
}

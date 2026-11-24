import Foundation

/// `IrisAppPrivacyRepository` over iris, making the calls the App Privacy page makes.
public struct IrisSDKAppPrivacyRepository: IrisAppPrivacyRepository {
    private let api: any IrisAPI

    public init() {
        self.init(api: IrisClient())
    }

    init(api: any IrisAPI) {
        self.api = api
    }

    public func fetchPrivacy(session: IrisSession, appId: String) async throws -> AppPrivacy {
        async let usages = listDataUsages(session: session, appId: appId)
        async let state = api.get(path: "apps/\(appId)/dataUsagePublishState", cookies: session.cookies)
        let attributes = try JSONDecoder().decode(AppDataUsagesPublishStateResponse.self, from: try await state.0).data.attributes
        return AppPrivacy(appId: appId, dataUsages: try await usages,
                          isPublished: attributes.published ?? false, lastPublishedAt: attributes.lastPublished)
    }

    public func listDataUsages(session: IrisSession, appId: String) async throws -> [DataUsage] {
        let (data, _) = try await api.get(path: "apps/\(appId)/dataUsages", queryItems: [
            URLQueryItem(name: "include", value: "category,grouping,purpose,dataProtection"),
            URLQueryItem(name: "limit", value: "500"),
        ], cookies: session.cookies)
        return try JSONDecoder().decode(AppDataUsagesResponse.self, from: data).data.compactMap { row in
            guard let protection = row.relationships.dataProtection?.data?.id else { return nil }
            return DataUsage(
                id: row.id,
                appId: appId,
                category: row.relationships.category?.data.map { DataCategory(rawValue: $0.id) },
                purpose: row.relationships.purpose?.data.map { DataPurpose(rawValue: $0.id) },
                protection: DataProtection(rawValue: protection)
            )
        }
    }

    public func createDataUsage(session: IrisSession, appId: String, entry: DataUsageEntry) async throws {
        let body = try Self.encoder.encode(AppDataUsageCreateRequest(appId: appId, entry: entry))
        _ = try await api.post(path: "appDataUsages", body: body, cookies: session.cookies)
    }

    public func deleteDataUsage(session: IrisSession, dataUsageId: String) async throws {
        _ = try await api.delete(path: "appDataUsages/\(dataUsageId)", cookies: session.cookies)
    }

    public func publish(session: IrisSession, appId: String) async throws {
        let body = try Self.encoder.encode(AppDataUsagesPublishRequest(appId: appId))
        _ = try await api.patch(path: "appDataUsagesPublishState/\(appId)", body: body, cookies: session.cookies)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()
}

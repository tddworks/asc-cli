@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKProductVersions: ProductVersions, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listInAppPurchaseVersions(iapId: String) async throws -> [ASCKit.ProductVersion] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v2.inAppPurchases.id(iapId).versions.get(parameters: .init(limit: 200)),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map {
            map(id: $0.id, productId: iapId, kind: .inAppPurchase,
                version: $0.attributes?.version, state: $0.attributes?.state?.rawValue)
        }
    }

    public func listSubscriptionVersions(subscriptionId: String) async throws -> [ASCKit.ProductVersion] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.subscriptions.id(subscriptionId).versions.get(parameters: .init(limit: 200)),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map {
            map(id: $0.id, productId: subscriptionId, kind: .subscription,
                version: $0.attributes?.version, state: $0.attributes?.state?.rawValue)
        }
    }

    public func listSubscriptionGroupVersions(groupId: String) async throws -> [ASCKit.ProductVersion] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.subscriptionGroups.id(groupId).versions.get(parameters: .init(limit: 200)),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map {
            map(id: $0.id, productId: groupId, kind: .subscriptionGroup,
                version: $0.attributes?.version, state: $0.attributes?.state?.rawValue)
        }
    }

    /// The three SDK version types share the same attributes and state values.
    private func map(
        id: String, productId: String, kind: ASCKit.ProductVersionKind, version: Int?, state: String?
    ) -> ASCKit.ProductVersion {
        ASCKit.ProductVersion(
            id: id, productId: productId, kind: kind, version: version,
            state: state.flatMap(ASCKit.ProductVersionState.init(rawValue:)) ?? .prepareForSubmission
        )
    }
}

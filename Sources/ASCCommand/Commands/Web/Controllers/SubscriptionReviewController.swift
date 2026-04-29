import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return the subscription review screenshot and promotional images.
struct SubscriptionReviewController: Sendable {
    let repo: any SubscriptionReviewRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/review-screenshot") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let item = try await self.repo.getReviewScreenshot(subscriptionId: subscriptionId)
            return try restFormat(item.map { [$0] } ?? [])
        }

        group.post("/subscriptions/:subscriptionId/review-screenshot") { request, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            return await uploadReviewBodyResponse(
                label: "subscription-review-screenshot",
                request: request,
                fileExtension: extensionFor(contentType: request.headers[.contentType], fallback: "png"),
                upload: { try await self.repo.uploadReviewScreenshot(subscriptionId: subscriptionId, fileURL: $0) }
            )
        }

        group.get("/subscriptions/:subscriptionId/images") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let items = try await self.repo.listImages(subscriptionId: subscriptionId)
            return try restFormat(items)
        }

        group.post("/subscriptions/:subscriptionId/images") { request, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            return await uploadReviewBodyResponse(
                label: "subscription-images",
                request: request,
                fileExtension: extensionFor(contentType: request.headers[.contentType], fallback: "jpg"),
                upload: { try await self.repo.uploadImage(subscriptionId: subscriptionId, fileURL: $0) }
            )
        }
    }
}

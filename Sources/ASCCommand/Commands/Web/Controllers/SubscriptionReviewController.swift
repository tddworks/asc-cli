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

        group.delete("/subscription-review-screenshot/:screenshotId") { _, context -> Response in
            guard let screenshotId = context.parameters.get("screenshotId") else { return jsonError("Missing screenshotId") }
            try await self.repo.deleteReviewScreenshot(screenshotId: screenshotId)
            return restResponse("{\"deleted\":true}")
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

        group.delete("/subscription-images/:imageId") { _, context -> Response in
            guard let imageId = context.parameters.get("imageId") else { return jsonError("Missing imageId") }
            try await self.repo.deleteImage(imageId: imageId)
            return restResponse("{\"deleted\":true}")
        }
    }
}

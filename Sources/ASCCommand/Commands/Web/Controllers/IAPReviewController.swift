import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return IAP review screenshot + promotional images.
struct IAPReviewController: Sendable {
    let repo: any InAppPurchaseReviewRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/review-screenshot") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let item = try await self.repo.getReviewScreenshot(iapId: iapId)
            return try restFormat(item.map { [$0] } ?? [])
        }

        group.post("/iap/:iapId/review-screenshot") { request, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            return await uploadReviewBodyResponse(
                label: "iap-review-screenshot",
                request: request,
                fileExtension: extensionFor(contentType: request.headers[.contentType], fallback: "png"),
                upload: { try await self.repo.uploadReviewScreenshot(iapId: iapId, fileURL: $0) }
            )
        }

        group.get("/iap/:iapId/images") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let items = try await self.repo.listImages(iapId: iapId)
            return try restFormat(items)
        }

        group.post("/iap/:iapId/images") { request, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            return await uploadReviewBodyResponse(
                label: "iap-images",
                request: request,
                fileExtension: extensionFor(contentType: request.headers[.contentType], fallback: "jpg"),
                upload: { try await self.repo.uploadImage(iapId: iapId, fileURL: $0) }
            )
        }
    }
}

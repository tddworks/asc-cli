# IAP & Subscription Review Assets

Review screenshots (one per IAP/subscription) and 1024×1024 promotional images (multiple per IAP). All uploads go through ASC's standard reserve → upload chunks → commit-with-MD5 protocol on top of `URLSession`.

## CLI commands

### IAP review screenshot (singleton)

| Command | Required flags |
|---------|----------------|
| `asc iap-review-screenshot get --iap-id <id>` | `--iap-id` — returns empty `data: []` when no screenshot |
| `asc iap-review-screenshot upload --iap-id <id> --file <path>` | both |
| `asc iap-review-screenshot delete --screenshot-id <id>` | `--screenshot-id` |

### IAP promotional images (multiple per IAP)

| Command | Required flags |
|---------|----------------|
| `asc iap-images list --iap-id <id>` | `--iap-id` |
| `asc iap-images upload --iap-id <id> --file <path>` | both |
| `asc iap-images delete --image-id <id>` | `--image-id` |

### Subscription review screenshot (singleton)

| Command | Required flags |
|---------|----------------|
| `asc subscription-review-screenshot get --subscription-id <id>` | `--subscription-id` |
| `asc subscription-review-screenshot upload --subscription-id <id> --file <path>` | both |
| `asc subscription-review-screenshot delete --screenshot-id <id>` | `--screenshot-id` |

## Upload workflow

All asset uploads follow the same 3-step protocol:

```
Step 1: Reserve     POST /v1/<asset>/  with fileName + fileSize
                    → returns reservation id + uploadOperations[]
Step 2: Upload      iterate uploadOperations, upload each chunk via URLSession
                    (each operation has url, method, offset, length, requestHeaders)
Step 3: Commit      PATCH /v1/<asset>/{id}  with sourceFileChecksum (MD5) + isUploaded=true
                    → returns final resource with imageAsset
```

MD5 is computed via `Data.md5HexString` (CryptoKit `Insecure.MD5`).

## State-aware affordances

| Aggregate | Trigger | Affordance suppressed |
|-----------|---------|-----------------------|
| `InAppPurchasePromotionalImage` | `state.isPendingReview == true` (waiting/in review) | `delete` |
| `InAppPurchaseReviewScreenshot` / `SubscriptionReviewScreenshot` | `assetState == .awaitingUpload` | `delete` (only `upload` offered as recovery) |

`AssetState` exposes `isComplete` (true for `uploadComplete` or `complete`) and `hasFailed` (true for `failed`).

## Domain models

```swift
public struct InAppPurchaseReviewScreenshot: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let iapId: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetState?  // .awaitingUpload, .uploadComplete, .complete, .failed
}

public struct InAppPurchasePromotionalImage: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let iapId: String
    public let fileName: String
    public let fileSize: Int
    public let state: ImageState?       // .approved, .waitingForReview, …
}

public struct SubscriptionReviewScreenshot: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let subscriptionId: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetState?
}
```

`InAppPurchase` advertises `getReviewScreenshot` + `listImages`. `Subscription` advertises `getReviewScreenshot`.

## REST endpoints

| Path | Method |
|------|--------|
| `/api/v1/iap/:iapId/review-screenshot` | GET — singleton; resource-by-id path is `/api/v1/iap-review-screenshot/:iapId` because the `get` action treats the parent id as the resource handle |
| `/api/v1/iap/:iapId/images` | GET |
| `/api/v1/subscriptions/:subscriptionId/review-screenshot` | GET |

Upload and delete are CLI-only (multipart-style chunked upload would be a separate REST design).

## API reference

| Command | SDK call |
|---------|----------|
| `iap-review-screenshot get` | `APIEndpoint.v2.inAppPurchases.id(id).appStoreReviewScreenshot.get()` |
| `iap-review-screenshot upload` | reserve `POST /v1/inAppPurchaseAppStoreReviewScreenshots` → upload chunks via `URLSession` → commit `PATCH …/{id}` with MD5 |
| `iap-review-screenshot delete` | `APIEndpoint.v1.inAppPurchaseAppStoreReviewScreenshots.id(id).delete` |
| `iap-images list` | `APIEndpoint.v2.inAppPurchases.id(id).images.get()` |
| `iap-images upload / delete` | analogous to review screenshot |
| `subscription-review-screenshot *` | `APIEndpoint.v1.subscriptions.id(id).appStoreReviewScreenshot.get()` plus the matching create/patch/delete on `/v1/subscriptionAppStoreReviewScreenshots` |

## Testing

```bash
swift test --filter 'ReviewScreenshot|PromotionalImage|SDKInAppPurchaseReviewRepository|SDKSubscriptionReviewRepository'
```

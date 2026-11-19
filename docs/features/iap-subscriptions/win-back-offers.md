# Win-Back Offers

Offers to bring back lapsed subscribers, with configurable eligibility rules, priority, promotion intent, and per-territory pricing.

## CLI commands

| Command | Required flags |
|---------|----------------|
| `asc win-back-offers list --subscription-id <id>` | `--subscription-id` |
| `asc win-back-offers create --subscription-id <id> --reference-name <n> --offer-id <code> --duration <d> --mode <m> --periods <n> --paid-months <n> --since-min <n> --since-max <n> --start-date YYYY-MM-DD --priority HIGH|NORMAL` | all |
| `asc win-back-offers update --offer-id <id>` | `--offer-id` (any of `--start-date`, `--end-date`, `--priority`, `--promotion-intent`, `--paid-months`, `--since-min`, `--since-max`, `--wait-months`) |
| `asc win-back-offers delete --offer-id <id>` | `--offer-id` |
| `asc win-back-offers prices list --offer-id <id>` | `--offer-id` |

Optional create flags: `--end-date YYYY-MM-DD`, `--wait-months <n>`, `--promotion-intent NOT_PROMOTED|USE_AUTO_GENERATED_ASSETS`, `--price USA=spp-1 ...` (repeatable).

## Eligibility model

```
paid-months                 # months the customer must have been a paid subscriber before they qualify
since-min .. since-max      # months since their last subscription (range)
wait-months                 # minimum gap between offers shown to the same customer (optional)
```

`priority` controls which offer wins when multiple match. `promotion-intent` controls whether the offer auto-generates marketing assets.

## SDK gap

The generated `WinBackOfferPriceInlineCreate` is missing `territory` and `subscriptionPricePoint` relationship fields. `SDKWinBackOfferRepository.createWinBackOffer` builds the body manually with a private `AnyCodable` type-erased enum. The ID convention matches ASC web (`${newPromoOfferPrice-N}`, 1-based).

## Domain model

```swift
public struct WinBackOffer: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let subscriptionId: String
    public let referenceName: String
    public let offerId: String
    public let duration: SubscriptionOfferDuration
    public let offerMode: SubscriptionOfferMode
    public let periodCount: Int
    public let customerEligibilityPaidSubscriptionDurationInMonths: Int
    public let customerEligibilityTimeSinceLastSubscribedMin: Int
    public let customerEligibilityTimeSinceLastSubscribedMax: Int
    public let customerEligibilityWaitBetweenOffersInMonths: Int?
    public let startDate: String
    public let endDate: String?
    public let priority: WinBackOfferPriority           // HIGH | NORMAL
    public let promotionIntent: WinBackOfferPromotionIntent?
}

public struct WinBackOfferPrice: Sendable, Equatable, Identifiable, Codable { ... }
public struct WinBackOfferPriceInput: Sendable, Equatable { ... }
```

`Subscription` advertises `listWinBackOffers`.

## REST endpoints

| Path | Method |
|------|--------|
| `/api/v1/subscriptions/:subscriptionId/win-back-offers` | GET |
| `/api/v1/win-back-offers/:offerId/prices` | GET |

## API reference

| Command | SDK call |
|---------|----------|
| `list` | `APIEndpoint.v1.subscriptions.id(id).winBackOffers.get()` |
| `create` | manual `Request<WinBackOfferResponse>(path: "/v1/winBackOffers", method: "POST", body: AnyCodable…)` |
| `update` | `APIEndpoint.v1.winBackOffers.id(id).patch(WinBackOfferUpdateRequest)` |
| `delete` | `APIEndpoint.v1.winBackOffers.id(id).delete` |
| `prices list` | `APIEndpoint.v1.winBackOffers.id(id).prices.get()` |

## Testing

```bash
swift test --filter 'WinBackOffer'
```

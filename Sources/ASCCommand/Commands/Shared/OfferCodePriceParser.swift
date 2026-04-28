import ArgumentParser
import Domain

/// Parses CLI `--price <territory>=<price-point-id>` and `--free-territory <territory>`
/// flags into the domain `OfferCodePriceInput` list.
///
/// Used by both `IAPOfferCodesCreate` and `SubscriptionOfferCodesCreate`. Centralised so
/// the two commands stay in sync and the validation message is consistent.
func parseOfferCodePrices(
    paid: [String],
    free: [String]
) throws -> [OfferCodePriceInput] {
    var inputs: [OfferCodePriceInput] = []
    for entry in paid {
        let parts = entry.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            throw ValidationError(
                "Invalid --price '\(entry)'. Use --price <territory>=<price-point-id> (e.g. --price USA=pp-123)."
            )
        }
        inputs.append(.init(territory: String(parts[0]), pricePointId: String(parts[1])))
    }
    for territory in free {
        inputs.append(.init(territory: territory, pricePointId: nil))
    }
    return inputs
}

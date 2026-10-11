/// Re-reads a freshly uploaded asset until App Store Connect has finished processing it.
public enum AssetProcessingWait {
    public static let pollIntervalNanos: UInt64 = 2_000_000_000
    public static let maxAttempts = 90

    /// Returns the latest read once it's no longer pending, or after `maxAttempts` reads.
    public static func untilProcessed<Asset: Sendable>(
        _ asset: Asset,
        isPending: (Asset) -> Bool,
        sleep: @Sendable (UInt64) async throws -> Void,
        reread: () async throws -> Asset?
    ) async throws -> Asset {
        var latest = asset
        var attempts = 0
        while isPending(latest), attempts < maxAttempts {
            try await sleep(pollIntervalNanos)
            latest = try await reread() ?? latest
            attempts += 1
        }
        return latest
    }
}

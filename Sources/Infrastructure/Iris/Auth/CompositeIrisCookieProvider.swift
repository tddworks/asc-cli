import Domain
import Foundation

/// Tries each provider in order; the first one that successfully resolves wins.
/// Default order: SRP-stored → browser → (env handled inside browser provider).
///
/// This lets a user log in via `asc iris auth login` (slice 6) and have every iris
/// command pick up the session immediately, without removing the browser-cookie
/// fallback for users who haven't run SRP login.
public struct CompositeIrisCookieProvider: IrisCookieProvider {
    private let providers: [any IrisCookieProvider]

    public init(providers: [any IrisCookieProvider]) {
        self.providers = providers
    }

    public func resolveSession() throws -> IrisSession {
        var lastError: Error?
        for provider in providers {
            do {
                return try provider.resolveSession()
            } catch {
                lastError = error
            }
        }
        throw lastError ?? IrisCookieError.noCookiesFound
    }

    public func resolveStatus() throws -> IrisStatus {
        var lastError: Error?
        for provider in providers {
            do {
                return try provider.resolveStatus()
            } catch {
                lastError = error
            }
        }
        throw lastError ?? IrisCookieError.noCookiesFound
    }
}

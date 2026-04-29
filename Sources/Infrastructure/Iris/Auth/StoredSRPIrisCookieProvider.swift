import Domain
import Foundation

/// Surfaces an `IrisAuthSession` previously written by `asc iris auth login` as an
/// `IrisCookieProvider` — so any iris-using command (`iris apps list`, etc.) just
/// works once the user has logged in via SRP.
///
/// Returns `nil`-equivalent (throws `IrisCookieError.noCookiesFound`) when no session
/// is present or the session has expired. Composition with browser/env cookies is the
/// composite's job, not this provider's.
public struct StoredSRPIrisCookieProvider: IrisCookieProvider {
    private let sessionRepository: any IrisSessionRepository

    public init(sessionRepository: any IrisSessionRepository = FileIrisSessionRepository()) {
        self.sessionRepository = sessionRepository
    }

    public func resolveSession() throws -> IrisSession {
        guard let session = try sessionRepository.current(), session.expiresAt > Date() else {
            throw IrisCookieError.noCookiesFound
        }
        return IrisSession(cookies: session.cookies)
    }

    public func resolveStatus() throws -> IrisStatus {
        let session = try resolveSession()
        let count = session.cookies.components(separatedBy: "; ").filter { !$0.isEmpty }.count
        return IrisStatus(source: .srpLogin, cookieCount: count)
    }
}

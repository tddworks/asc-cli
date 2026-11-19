import Foundation
import Mockable

/// Persists `IrisAuthSession` for reuse across `asc` invocations.
///
/// One session at a time — the protocol is CRUD on a singleton resource. Implementations
/// live in Infrastructure (`KeychainIrisSessionRepository` on macOS, `FileIrisSessionRepository`
/// for the disk fallback, `CompositeIrisSessionRepository` to chain them).
@Mockable
public protocol IrisSessionRepository: Sendable {
    func save(_ session: IrisAuthSession) throws
    func current() throws -> IrisAuthSession?
    func delete() throws
}

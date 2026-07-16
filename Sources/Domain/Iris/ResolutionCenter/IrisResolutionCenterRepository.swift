import Foundation
import Mockable

/// Repository for reading Resolution Center data via the iris private API.
///
/// Separate from `SubmissionRepository` (public SDK, key-auth) so the two auth
/// surfaces don't tangle: `asc review-submissions *` keeps zero-iris
/// dependency, while this path is reachable only when iris cookies are
/// available.
@Mockable
public protocol IrisResolutionCenterRepository: Sendable {
    /// One user-visible operation — "read the Resolution Center for this
    /// submission". The adapter composes the thread → messages → rejections
    /// iris calls behind it.
    func getResolution(
        session: IrisSession,
        submissionId: String
    ) async throws -> ResolutionCenterDetail

    /// Fetch one attachment's bytes from its Apple-signed URL. Adapters must
    /// refuse URLs that fail `ResolutionCenterAttachment.isValidDownloadURL`.
    func downloadAttachment(
        session: IrisSession,
        url: String
    ) async throws -> Data
}

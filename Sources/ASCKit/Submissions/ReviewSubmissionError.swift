import Foundation

/// Apple refused to add an item to, or submit, a review submission. `reasons` are the
/// specific problems Apple listed (missing screenshots, pricing, privacy answers, …),
/// which its headline message only points at.
public enum ReviewSubmissionError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    case refused(message: String, reasons: [String])
    /// The version can't go to review in its current state (only an editable one can).
    case versionNotEditable(versionString: String, state: AppStoreVersionState)

    public var description: String {
        switch self {
        case .refused(let message, let reasons):
            (["Apple refused the review submission: \(message)"] + reasons.map { "  - \($0)" })
                .joined(separator: "\n")
        case .versionNotEditable(let versionString, let state):
            "Version \(versionString) can't go to review while it is \(state.displayName). "
                + "Only a version being prepared for submission, or one that was rejected, can."
        }
    }

    public var errorDescription: String? { description }
}

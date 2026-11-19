extension AppStoreVersion {
    /// Sends this version to App Review: into its app's open draft for its platform
    /// (Apple allows one), adding the version unless the draft already holds it,
    /// then submitting the draft. Only an editable version can go — the same
    /// `isEditable` that offers the `submitForReview` affordance.
    public func submitForReview(to submissions: any SubmissionRepository) async throws -> ReviewSubmission {
        guard isEditable else {
            throw ReviewSubmissionError.versionNotEditable(versionString: versionString, state: state)
        }
        let draft = try await submissions.createSubmission(appId: appId, platform: platform)
        // A refused submit leaves its draft open, so it may already hold this version.
        let items = try await submissions.listSubmissionItems(submissionId: draft.id)
        if !items.contains(where: { $0.linkedResourceId == id }) {
            _ = try await submissions.addItem(submissionId: draft.id, target: .appStoreVersion(id))
        }
        return try await submissions.submit(submissionId: draft.id)
    }
}

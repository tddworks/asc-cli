import { useState } from 'react';
import { useSubmission } from '../Submission.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

export default function SubmissionPage() {
  const [versionId, setVersionId] = useState('');
  const [checkedVersionId, setCheckedVersionId] = useState('');
  const { submission, loading, error } = useSubmission(checkedVersionId || 'v-1');

  return (
    <div>
      <h2>Submission</h2>

      <div className="card">
        <div className="card-header">
          <h3>Submit for Review</h3>
        </div>
        <div className="card-body">
          <div className="form-group">
            <label>Version ID</label>
            <input
              type="text"
              className="form-control"
              placeholder="Enter version ID"
              value={versionId}
              onChange={(e) => setVersionId(e.target.value)}
            />
          </div>
          <div className="form-row" style={{ gap: 8, marginTop: 12 }}>
            <button
              className="btn btn-primary btn-sm"
              onClick={() => setCheckedVersionId(versionId)}
              disabled={!versionId}
            >
              Check Readiness
            </button>
            <button
              className="btn btn-primary btn-sm"
              disabled={!submission || !submission.canSubmit}
            >
              Submit for Review
            </button>
          </div>

          {loading && <div className="spinner" style={{ marginTop: 12 }}>Loading submission...</div>}
          {error && <div className="error" style={{ marginTop: 12 }}>Error: {error.message}</div>}

          {submission && !loading && (
            <div style={{ marginTop: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                <span style={{ fontWeight: 600 }}>Submission {submission.id}</span>
                <span className={`status ${submission.isAccepted ? 'live' : submission.isRejected ? 'rejected' : submission.isInReview ? 'review' : 'pending'}`}>
                  {submission.displayState}
                </span>
              </div>
              <AffordanceBar affordances={submission.affordances} />
            </div>
          )}
        </div>
      </div>

      <div className="card" style={{ marginTop: 16 }}>
        <div className="card-header">
          <h3>Review Contact &amp; Demo Account</h3>
        </div>
        <div className="card-body">
          <div className="form-row">
            <div className="form-group" style={{ flex: 1 }}>
              <label>Contact First Name</label>
              <input type="text" className="form-control" placeholder="First name" />
            </div>
            <div className="form-group" style={{ flex: 1 }}>
              <label>Contact Last Name</label>
              <input type="text" className="form-control" placeholder="Last name" />
            </div>
          </div>
          <div className="form-row">
            <div className="form-group" style={{ flex: 1 }}>
              <label>Contact Email</label>
              <input type="email" className="form-control" placeholder="email@example.com" />
            </div>
            <div className="form-group" style={{ flex: 1 }}>
              <label>Contact Phone</label>
              <input type="tel" className="form-control" placeholder="+1 (555) 000-0000" />
            </div>
          </div>
          <div className="form-row">
            <div className="form-group" style={{ flex: 1 }}>
              <label>Demo Account Username</label>
              <input type="text" className="form-control" placeholder="demo@example.com" />
            </div>
            <div className="form-group" style={{ flex: 1 }}>
              <label>Demo Account Password</label>
              <input type="password" className="form-control" placeholder="password" />
            </div>
          </div>
          <div className="form-group">
            <label>Notes for Reviewer</label>
            <textarea className="form-control" rows={3} placeholder="Any special instructions for the reviewer..." />
          </div>
        </div>
      </div>
    </div>
  );
}

import { useState } from 'react';
import { useTestFlight } from '../TestFlight.hooks.ts';
import { BetaGroupCard } from '../components/BetaGroupCard.tsx';

export default function TestFlightPage({ appId = 'app-1' }: { appId?: string }) {
  const { betaGroups, loading, error } = useTestFlight(appId);
  const [testerEmail, setTesterEmail] = useState('');

  if (loading) return <div className="spinner">Loading beta groups...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div>
      <h2>TestFlight</h2>
      <div className="grid-2">
        <div className="card">
          <div className="card-header">
            <h3>Beta Groups</h3>
          </div>
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Group</th>
                  <th>Type</th>
                  <th>Public Link</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {betaGroups.map((g) => <BetaGroupCard key={g.id} group={g} />)}
              </tbody>
            </table>
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <h3>Quick Tester Actions</h3>
          </div>
          <div className="card-body">
            <div className="form-group">
              <label>Add Tester by Email</label>
              <div style={{ display: 'flex', gap: 8 }}>
                <input
                  type="email"
                  className="form-control"
                  placeholder="tester@example.com"
                  value={testerEmail}
                  onChange={(e) => setTesterEmail(e.target.value)}
                />
                <button className="btn btn-primary btn-sm" disabled={!testerEmail}>
                  Add
                </button>
              </div>
            </div>
            <div className="form-group" style={{ marginTop: 16 }}>
              <label>Bulk Actions</label>
              <div style={{ display: 'flex', gap: 8 }}>
                <button className="btn btn-sm">Import CSV</button>
                <button className="btn btn-sm">Export CSV</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

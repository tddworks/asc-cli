import { useSubscriptionGroups } from '../Subscription.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

export default function SubscriptionPage({ appId = 'app-1' }: { appId?: string }) {
  const { groups, loading, error } = useSubscriptionGroups(appId);

  if (loading) return <div className="spinner">Loading subscriptions...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div>
      <div className="card" style={{ marginBottom: 16 }}>
        <div className="toolbar">
          <div className="toolbar-left"><h3>Subscription Groups</h3></div>
        </div>
        <div className="table-wrapper">
          <table>
            <thead>
              <tr><th>Group</th><th>App ID</th><th>Actions</th></tr>
            </thead>
            <tbody>
              {groups.map((g) => (
                <tr key={g.id}>
                  <td className="cell-primary">{g.referenceName}</td>
                  <td className="cell-mono">{g.appId}</td>
                  <td><AffordanceBar affordances={g.affordances} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="card">
        <div className="toolbar">
          <div className="toolbar-left"><h3>Offer Codes</h3></div>
        </div>
        <div className="card-body" style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-secondary btn-sm">Create Offer Code</button>
          <button className="btn btn-secondary btn-sm">View Active Offers</button>
        </div>
      </div>
    </div>
  );
}

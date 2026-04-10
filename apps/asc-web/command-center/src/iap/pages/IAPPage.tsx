import { useInAppPurchases } from '../IAP.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

export default function IAPPage({ appId = 'app-1' }: { appId?: string }) {
  const { iaps, loading, error } = useInAppPurchases(appId);

  if (loading) return <div className="spinner">Loading in-app purchases...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="card">
      <div className="toolbar">
        <div className="toolbar-left"><h3>In-App Purchases</h3></div>
      </div>
      <div className="table-wrapper">
        <table>
          <thead>
            <tr><th>Name</th><th>Product ID</th><th>Type</th><th>State</th><th>Actions</th></tr>
          </thead>
          <tbody>
            {iaps.map((p) => (
              <tr key={p.id}>
                <td className="cell-primary">{p.name}</td>
                <td className="cell-mono">{p.productId}</td>
                <td><span className="platform-badge">{p.inAppPurchaseType}</span></td>
                <td><span className={`status ${p.isApproved ? 'live' : 'pending'}`}>{p.state}</span></td>
                <td><AffordanceBar affordances={p.affordances} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

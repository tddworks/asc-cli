import { useIrisApps } from '../Iris.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

export default function IrisPage() {
  const { apps, loading, error } = useIrisApps();

  if (loading) return <div className="spinner">Loading Iris...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div>
      <div className="card" style={{ marginBottom: 16 }}>
        <div className="card-body" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ width: 10, height: 10, borderRadius: '50%', background: 'var(--success)' }} />
          <div>
            <div style={{ fontWeight: 600 }}>Session Active</div>
            <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Source: cookie</div>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="toolbar">
          <div className="toolbar-left"><h3>Iris (Private API)</h3></div>
        </div>
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Bundle ID</th>
                <th>SKU</th>
                <th>Platforms</th>
                <th>ID</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {apps.map((a) => (
                <tr key={a.id}>
                  <td className="cell-primary">{a.name}</td>
                  <td className="cell-mono">{a.bundleId}</td>
                  <td className="cell-mono">{a.sku}</td>
                  <td>{a.platforms.map((p) => <span key={p} className="platform-badge" style={{ marginRight: 4 }}>{p}</span>)}</td>
                  <td className="cell-mono">{a.id}</td>
                  <td><AffordanceBar affordances={a.affordances} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

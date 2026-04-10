import { useReports } from '../Report.hooks.ts';

const categoryIcons: Record<string, string> = {
  sales: '📊',
  finance: '💰',
  analytics: '📈',
  performance: '⚡',
};

const perfMetrics = [
  { label: 'App Hang Rate', key: 'hang' },
  { label: 'Launch Time', key: 'launch' },
  { label: 'Memory Usage', key: 'memory' },
  { label: 'Disk Writes', key: 'disk' },
  { label: 'Battery Usage', key: 'battery' },
  { label: 'Scrolling', key: 'scroll' },
];

export default function ReportsPage() {
  const { reports, loading, error } = useReports();

  if (loading) return <div className="spinner">Loading reports...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div>
      <h2>Reports</h2>
      <div className="grid-3">
        {reports.map((r) => (
          <div key={r.id} className="card">
            <div className="card-body" style={{ textAlign: 'center', padding: 24 }}>
              <div style={{ fontSize: 40, marginBottom: 12 }}>{categoryIcons[r.category] ?? '📄'}</div>
              <h3>{r.name}</h3>
              <p style={{ color: 'var(--text-muted)', marginBottom: 16 }}>{r.description}</p>
              <button className="btn btn-primary btn-sm" title={r.command}>Download</button>
            </div>
          </div>
        ))}
      </div>

      <div className="card" style={{ marginTop: 24 }}>
        <div className="card-header">
          <h3>Performance Metrics</h3>
        </div>
        <div className="card-body" style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {perfMetrics.map((m) => (
            <button key={m.key} className="btn btn-sm">{m.label}</button>
          ))}
        </div>
      </div>
    </div>
  );
}

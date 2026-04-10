import { useDashboard } from '../Dashboard.hooks.ts';
import { BuildRow } from '../../build/components/BuildRow.tsx';

interface StatCardProps {
  label: string;
  value: number;
  icon: string;
  bg: string;
  color: string;
}

function StatCard({ label, value, icon, bg, color }: StatCardProps) {
  return (
    <div className="stat-card">
      <div className="stat-header">
        <div className="stat-icon" style={{ background: bg, color }}>{icon}</div>
      </div>
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
    </div>
  );
}

export default function DashboardPage() {
  const { data, loading } = useDashboard();

  if (loading || !data) return <div className="spinner">Loading dashboard...</div>;

  return (
    <div>
      <h2>Dashboard</h2>

      {/* Stats */}
      <div className="dashboard-stats">
        <StatCard label="Total Apps" value={data.totalApps} icon="📱" bg="rgba(37,99,235,0.1)" color="#2563EB" />
        <StatCard label="Live on Store" value={data.liveVersions} icon="🟢" bg="rgba(5,150,105,0.1)" color="#059669" />
        <StatCard label="Valid Builds" value={data.recentBuilds} icon="🔨" bg="rgba(124,58,237,0.1)" color="#7C3AED" />
        <StatCard label="Pending Review" value={data.pendingReviews} icon="⏳" bg="rgba(217,119,6,0.1)" color="#D97706" />
      </div>

      {/* Two-column grid */}
      <div className="grid-2">
        {/* Recent Activity */}
        <div className="card">
          <h3>Recent Activity</h3>
          <div className="table-wrapper">
            <table>
              <thead>
                <tr>
                  <th>Build</th>
                  <th>Version</th>
                  <th>Usable</th>
                  <th>Status</th>
                  <th>Expired</th>
                  <th>Uploaded</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.builds.slice(0, 5).map((b) => (
                  <BuildRow key={b.id} build={b} />
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Release Pipeline */}
        <div className="card">
          <h3>Release Pipeline</h3>
          <div style={{ padding: 16 }}>
            {data.versions.map((v) => (
              <div key={v.id} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
                <div style={{
                  width: 10, height: 10, borderRadius: '50%',
                  background: v.isLive ? '#059669' : v.isPending ? '#D97706' : v.isRejected ? '#DC2626' : '#6B7280',
                }} />
                <div>
                  <div style={{ fontWeight: 600 }}>{v.versionString}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>{v.state}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="card" style={{ marginTop: 16 }}>
        <h3>Quick Actions</h3>
        <div style={{ display: 'flex', gap: 8, padding: 16 }}>
          <button className="btn btn-primary">New Version</button>
          <button className="btn btn-secondary">Upload Build</button>
          <button className="btn btn-secondary">View Reviews</button>
        </div>
      </div>
    </div>
  );
}

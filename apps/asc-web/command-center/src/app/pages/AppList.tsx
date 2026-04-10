import { useApps } from '../App.hooks.ts';
import { AppCard } from '../components/AppCard.tsx';

export default function AppList() {
  const { apps, loading, error } = useApps();

  if (loading) return <div className="spinner">Loading apps...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div>
      <div className="card">
        <div className="toolbar">
          <div className="toolbar-left"><h3>Apps</h3></div>
        </div>
        <div className="card-body" style={{ padding: 0 }}>
          <div className="grid-3" style={{ padding: 16 }}>
            {apps.map((app) => (
              <AppCard key={app.id} app={app} />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

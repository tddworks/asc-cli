import { useParams } from 'react-router-dom';
import { useApp } from '../App.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

const appColors = ['#2563EB','#7C3AED','#059669','#D97706','#DC2626','#0891B2','#4F46E5','#EA580C'];

function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash + str.charCodeAt(i)) | 0;
  }
  return Math.abs(hash);
}

export default function AppDetail() {
  const { appId } = useParams<{ appId: string }>();
  const { app, loading, error } = useApp(appId!);

  if (loading) return <div className="spinner">Loading app...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;
  if (!app) return <div className="empty-state">App not found</div>;

  const color = appColors[hashCode(app.id) % appColors.length];
  const initial = app.name.charAt(0).toUpperCase();

  return (
    <div>
      <div className="card">
        <div className="toolbar">
          <div className="toolbar-left">
            <div className="app-icon" style={{ background: color }}>{initial}</div>
            <h3>{app.name}</h3>
          </div>
        </div>
        <div className="card-body">
          <dl>
            <dt>Bundle ID</dt><dd>{app.bundleId}</dd>
            <dt>SKU</dt><dd>{app.sku}</dd>
            <dt>Locale</dt><dd>{app.primaryLocale}</dd>
          </dl>
          <AffordanceBar affordances={app.affordances} />
        </div>
      </div>
    </div>
  );
}

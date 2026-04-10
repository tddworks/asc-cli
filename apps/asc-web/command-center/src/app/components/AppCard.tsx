import { App } from '../App.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

interface Props {
  app: App;
}

const appColors = ['#2563EB','#7C3AED','#059669','#D97706','#DC2626','#0891B2','#4F46E5','#EA580C'];

function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash + str.charCodeAt(i)) | 0;
  }
  return Math.abs(hash);
}

export function AppCard({ app }: Props) {
  const color = appColors[hashCode(app.id) % appColors.length];
  const initial = app.name.charAt(0).toUpperCase();

  return (
    <div className="app-card">
      <div className="app-card-top">
        <div className="app-icon" style={{ background: color }}>{initial}</div>
        <div className="app-card-info">
          <div className="app-card-name">{app.name}</div>
          <div className="app-card-bundle">{app.bundleId}</div>
        </div>
      </div>
      <div className="app-card-meta">
        <span className="app-meta-item">{app.primaryLocale}</span>
        <span className="app-meta-item">{app.id}</span>
      </div>
      <div style={{ marginTop: 12, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        <AffordanceBar affordances={app.affordances} />
      </div>
    </div>
  );
}

import { App } from '../App.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

interface Props {
  app: App;
}

export function AppCard({ app }: Props) {
  return (
    <div className="card">
      <h3>{app.displayName}</h3>
      <span className="sku">{app.sku}</span>
      {app.hasContentRights && <span className="badge">Content Rights</span>}
      <AffordanceBar affordances={app.affordances} />
    </div>
  );
}

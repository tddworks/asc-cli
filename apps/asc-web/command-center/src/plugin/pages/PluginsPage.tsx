import { useState } from 'react';

interface PluginInfo {
  name: string;
  version: string;
  author: string;
  description: string;
  categories: string[];
  installed: boolean;
}

const mockPlugins: PluginInfo[] = [
  { name: 'discord-notify', version: '1.0.0', author: 'Community', description: 'Send build notifications to Discord channels', categories: ['Notifications'], installed: true },
  { name: 'slack-alerts', version: '2.1.0', author: 'Community', description: 'Slack integration for review and build alerts', categories: ['Notifications'], installed: true },
  { name: 'screenshot-ai', version: '0.9.0', author: 'ASC Team', description: 'AI-powered screenshot generation and localization', categories: ['Screenshots', 'AI'], installed: false },
  { name: 'analytics-pro', version: '1.5.0', author: 'Community', description: 'Advanced analytics dashboards and reports', categories: ['Analytics'], installed: false },
  { name: 'auto-reply', version: '1.0.0', author: 'Community', description: 'Auto-reply to negative reviews using templates', categories: ['Reviews', 'AI'], installed: false },
];

const appColors = ['#2563EB', '#7C3AED', '#059669', '#D97706', '#DC2626', '#0891B2', '#4F46E5', '#EA580C'];

export default function PluginsPage() {
  const [tab, setTab] = useState<'installed' | 'market'>('installed');

  const installed = mockPlugins.filter((p) => p.installed);
  const market = mockPlugins.filter((p) => !p.installed);
  const displayed = tab === 'installed' ? installed : market;

  return (
    <div>
      <div className="dashboard-stats" style={{ marginBottom: 16 }}>
        <div className="stat-card">
          <div className="stat-value">{installed.length}</div>
          <div className="stat-label">Installed</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{market.length}</div>
          <div className="stat-label">Available</div>
        </div>
      </div>

      <div className="card">
        <div className="toolbar">
          <div className="toolbar-left">
            <h3>Plugins</h3>
            <div className="filter-group">
              <button className={`filter-btn ${tab === 'installed' ? 'active' : ''}`} onClick={() => setTab('installed')}>Installed</button>
              <button className={`filter-btn ${tab === 'market' ? 'active' : ''}`} onClick={() => setTab('market')}>Marketplace</button>
            </div>
          </div>
        </div>
        <div className="card-body" style={{ padding: 0 }}>
          <div className="grid-3" style={{ padding: 16 }}>
            {displayed.map((p, i) => (
              <div key={p.name} className="app-card">
                <div className="app-card-top">
                  <div className="app-icon" style={{ background: appColors[i % appColors.length] }}>
                    {p.name.charAt(0).toUpperCase()}
                  </div>
                  <div className="app-card-info">
                    <div className="app-card-name">{p.name}</div>
                    <div className="app-card-bundle">v{p.version} &middot; {p.author}</div>
                  </div>
                </div>
                <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: '8px 0' }}>{p.description}</p>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>{p.categories.map((c) => <span key={c} className="platform-badge" style={{ marginRight: 4 }}>{c}</span>)}</div>
                  {p.installed
                    ? <button className="btn btn-secondary btn-sm" style={{ color: 'var(--danger)' }}>Uninstall</button>
                    : <button className="btn btn-primary btn-sm">Install</button>
                  }
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

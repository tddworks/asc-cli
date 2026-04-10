import { NavLink } from 'react-router-dom';
import { usePluginRegistry } from '../../plugin/PluginContext.tsx';

interface NavItem {
  path: string;
  label: string;
}

const coreItems: { section: string; items: NavItem[] }[] = [
  {
    section: 'Overview',
    items: [
      { path: '/', label: 'Dashboard' },
      { path: '/apps', label: 'Apps' },
    ],
  },
  {
    section: 'Release',
    items: [
      { path: '/apps/app-1/versions', label: 'Versions' },
      { path: '/builds', label: 'Builds' },
      { path: '/testflight', label: 'TestFlight' },
      { path: '/submissions', label: 'Submissions' },
    ],
  },
  {
    section: 'Metadata',
    items: [
      { path: '/screenshots', label: 'Screenshots' },
      { path: '/reviews', label: 'Reviews' },
    ],
  },
  {
    section: 'Monetization',
    items: [
      { path: '/reports', label: 'Reports' },
    ],
  },
  {
    section: 'Infrastructure',
    items: [
      { path: '/code-signing', label: 'Code Signing' },
      { path: '/xcode-cloud', label: 'Xcode Cloud' },
      { path: '/plugins', label: 'Plugins' },
    ],
  },
];

export function Sidebar() {
  const registry = usePluginRegistry();
  const pluginItems = registry.getSidebarItems();

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <h2>ASC Manager</h2>
        <span className="sidebar-subtitle">App Store Connect</span>
      </div>
      <nav className="sidebar-nav">
        {coreItems.map(({ section, items }) => (
          <div key={section} className="nav-section">
            <div className="nav-section-title">{section}</div>
            {items.map((item) => (
              <NavLink
                key={item.path}
                to={item.path}
                className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
                end={item.path === '/'}
              >
                {item.label}
              </NavLink>
            ))}
          </div>
        ))}

        {pluginItems.length > 0 && (
          <div className="nav-section">
            <div className="nav-section-title">Plugins</div>
            {pluginItems.map((item) => (
              <NavLink
                key={item.id}
                to={item.path}
                className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
              >
                {item.label}
              </NavLink>
            ))}
          </div>
        )}
      </nav>
    </aside>
  );
}

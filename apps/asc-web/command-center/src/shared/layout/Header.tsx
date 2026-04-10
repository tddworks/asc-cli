import type { DataMode } from '../api-client.tsx';

interface Props {
  title: string;
  mode: DataMode;
  onToggleMode: () => void;
  onToggleTheme: () => void;
  onRefresh: () => void;
  onOpenCommandLog: () => void;
  onToggleSidebar: () => void;
}

export function Header({
  title,
  mode,
  onToggleMode,
  onToggleTheme,
  onRefresh,
  onOpenCommandLog,
  onToggleSidebar,
}: Props) {
  return (
    <header className="header">
      <div className="header-left">
        <button className="header-btn mobile-menu-btn" onClick={onToggleSidebar}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
        </button>
        <div>
          <div className="header-title" id="pageTitle">{title}</div>
          <div className="header-breadcrumb">
            <span>ASC Manager</span>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 18l6-6-6-6"/></svg>
            <span>{title}</span>
          </div>
        </div>
      </div>
      <div className="header-right">
        <div className="search-box">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input type="text" placeholder="Search commands..." />
          <kbd>/</kbd>
        </div>
        <button className="header-btn" onClick={onOpenCommandLog} title="Command Log">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>
        </button>
        <button className="header-btn" onClick={onToggleMode} title={`Data source: ${mode === 'mock' ? 'Mock' : 'CLI'}`} style={{position:'relative'}}>
          {mode === 'mock' ? (
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
          ) : (
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>
          )}
          <span style={{position:'absolute',top:4,right:4,width:8,height:8,borderRadius:'50%',background: mode === 'mock' ? 'var(--warning)' : 'var(--success)',border:'2px solid var(--bg-card)'}} />
        </button>
        <button className="theme-toggle" title="Toggle dark mode" onClick={onToggleTheme}>
          <svg className="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>
          <svg className="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>
        </button>
        <button className="header-btn" onClick={onRefresh} title="Refresh">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M23 4v6h-6"/><path d="M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
        </button>
      </div>
    </header>
  );
}

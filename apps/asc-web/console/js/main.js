// App entry point — wires shared infrastructure + console presentation
import { DataProvider } from '../../shared/infrastructure/data-provider.js';
import { renderNav, navigate, renderPage } from './presentation/navigation.js';
import { initTerminal, detectServer, getServerUrl, toggleTerminal, executeCommand, isTerminalOpen } from './presentation/terminal.js';
import { initPalette, toggle as togglePalette, isPaletteOpen } from './presentation/palette.js';
import { logCommand, logOutput, logError } from './presentation/state.js';
import { NAV } from './presentation/nav-data.js';
import { icon } from './presentation/icons.js';

// Wire DataProvider callbacks (shared infra → console presentation)
DataProvider._onCommand = logCommand;
DataProvider._onOutput = logOutput;
DataProvider._onError = logError;

// Init synchronous setup
renderNav();
renderPage();
initTerminal();
initPalette();

// Search
document.getElementById('search-input').addEventListener('input', (e) => {
  const q = e.target.value.toLowerCase().trim();
  if (!q) { renderNav(); return; }
  const nav = document.getElementById('nav');
  const allItems = NAV.flatMap(g => g.items);
  const matched = allItems.filter(item => {
    if (item.label.toLowerCase().includes(q)) return true;
    const allCmds = [...(item.entry || []), ...(item.workflow || [])];
    if (allCmds.some(c => c.includes(q))) return true;
    return false;
  });
  let html = `<div class="nav-group-title">Results (${matched.length})</div>`;
  matched.forEach(item => {
    html += `<button data-page="${item.id}" class="nav-item">
      ${icon(item.icon)}
      <span>${item.label}</span>
    </button>`;
  });
  nav.innerHTML = html;
  nav.querySelectorAll('[data-page]').forEach(btn => {
    btn.addEventListener('click', () => { e.target.value = ''; navigate(btn.dataset.page); });
  });
});

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
  if (e.key === 'k' && (e.metaKey || e.ctrlKey)) { e.preventDefault(); togglePalette(); }
  if (e.key === 'Escape') {
    if (isPaletteOpen()) togglePalette(false);
    else if (isTerminalOpen()) toggleTerminal(false);
  }
  if (e.key === '`' && e.ctrlKey) { e.preventDefault(); toggleTerminal(); }
});

// Event delegation
document.addEventListener('click', (e) => {
  const dashNav = e.target.closest('.dashboard-nav');
  if (dashNav) { navigate(dashNav.dataset.page); return; }

  const copyBtn = e.target.closest('.copy-cmd');
  if (copyBtn) {
    navigator.clipboard.writeText(copyBtn.dataset.cmd);
    const svg = copyBtn.querySelector('svg');
    svg.innerHTML = '<polyline points="20 6 9 17 4 12"/>';
    setTimeout(() => { svg.innerHTML = '<rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/>'; }, 1200);
    return;
  }

  const runBtn = e.target.closest('.run-cmd') || e.target.closest('.quick-cmd');
  if (runBtn) {
    toggleTerminal(true);
    setTimeout(() => executeCommand(runBtn.dataset.cmd), 350);
    return;
  }

  const affordanceBtn = e.target.closest('.run-affordance');
  if (affordanceBtn) { executeCommand(affordanceBtn.dataset.cmd); return; }

  const paletteItem = e.target.closest('.palette-item');
  if (paletteItem) {
    togglePalette(false);
    toggleTerminal(true);
    setTimeout(() => executeCommand(paletteItem.dataset.cmd), 350);
    return;
  }
});

// Async init — detect server
detectServer().then(online => {
  const el = document.getElementById('server-url');
  if (el) el.textContent = online ? getServerUrl() : 'offline — run: asc web-server';
});

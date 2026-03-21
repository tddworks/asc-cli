// App entry point — wires shared infrastructure + console presentation
import { DataProvider } from '../../shared/infrastructure/data-provider.js';
import { renderNav, navigate, renderPage } from './presentation/navigation.js';
import { initTerminal, detectServer, getServerUrl, toggleTerminal, executeCommand, isTerminalOpen } from './presentation/terminal.js';
import { initPalette, toggle as togglePalette, isPaletteOpen } from './presentation/palette.js';
import { logCommand, logOutput, logError } from './presentation/state.js';
import { initTheme, toggleTheme } from './presentation/theme.js';

// Wire DataProvider callbacks (shared infra → console presentation)
DataProvider._onCommand = logCommand;
DataProvider._onOutput = logOutput;
DataProvider._onError = logError;

// Init synchronous setup
initTheme();
renderNav();
renderPage();
initTerminal();
initPalette();

// Theme toggle
document.getElementById('theme-toggle').addEventListener('click', toggleTheme);

// Search input in header → opens the search overlay
document.getElementById('search-input').addEventListener('focus', (e) => {
  e.target.blur();
  togglePalette(true);
});

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
  // Cmd+K or / opens search overlay
  if (e.key === 'k' && (e.metaKey || e.ctrlKey)) { e.preventDefault(); togglePalette(); }
  if (e.key === '/' && !isPaletteOpen() && !isTerminalOpen() && !e.metaKey && !e.ctrlKey) {
    const tag = document.activeElement?.tagName;
    if (tag !== 'INPUT' && tag !== 'TEXTAREA') { e.preventDefault(); togglePalette(true); }
  }
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

  // Palette items are handled internally by palette.js via selectResult
});

// Async init — detect server
detectServer().then(online => {
  const el = document.getElementById('server-url');
  if (el) {
    if (online) {
      el.textContent = getServerUrl();
    } else if (window.location.protocol === 'https:') {
      el.textContent = 'offline — trust cert at https://localhost:8421';
    } else {
      el.textContent = 'offline — run: asc web-server';
    }
  }
});

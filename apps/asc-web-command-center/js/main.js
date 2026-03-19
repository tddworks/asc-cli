// App entry point — wires all layers together
import { initTheme } from './presentation/theme.js';
import { setupModalListeners } from './presentation/modal.js';
import { DataProvider } from '../../shared/infrastructure/data-provider.js';
import { updateModeIndicator } from './presentation/mode-indicator.js';
import { checkAuth } from './presentation/auth.js';
import { loadAppsForSelector } from './presentation/pages/apps.js';
import { renderPage, setupNavigation } from './presentation/navigation.js';
import { showToast } from './presentation/toast.js';
import { logCommand, logOutput, logError, state } from './presentation/state.js';

// Expose showToast globally for inline onclick handlers
window.showToast = showToast;

// Init synchronous setup
initTheme();
setupModalListeners();
setupNavigation();

// Wire mode toggle button (replaces inline onclick)
document.getElementById('modeToggle').addEventListener('click', () => {
  DataProvider.setMode(DataProvider._mode === 'cli' ? 'mock' : 'cli');
});

// Wire DataProvider callbacks to presentation layer
DataProvider._onCommand = logCommand;
DataProvider._onOutput = logOutput;
DataProvider._onError = logError;
DataProvider._onNotify = showToast;

// Async init
(async () => {
  await DataProvider.init();
  updateModeIndicator();

  // Wire mode change to re-render + update indicator
  DataProvider._onModeChange = () => {
    updateModeIndicator();
    renderPage(state.currentPage);
  };

  await checkAuth();
  await loadAppsForSelector();
  renderPage('dashboard');
})();

// Presentation: Page navigation + routing
import { state } from './state.js';
import { showToast } from './toast.js';
import { logCommand } from './state.js';

// Page modules — lazy loaded via dynamic import for cleaner dependency graph
import { renderDashboard, loadDashboard } from './pages/dashboard.js';
import { renderApps, loadApps } from './pages/apps.js';
import { renderVersions, loadVersions } from './pages/versions.js';
import { renderBuilds, loadBuilds } from './pages/builds.js';
import { renderTestFlight, loadTestFlight } from './pages/testflight.js';
import { renderSubmissions } from './pages/submissions.js';
import { renderAppInfo } from './pages/app-info.js';
import { renderScreenshots } from './pages/screenshots.js';
import { renderReviews, loadReviews } from './pages/reviews.js';
import { renderIAP, loadIAP } from './pages/iap.js';
import { renderSubscriptions, loadSubscriptions } from './pages/subscriptions.js';
import { renderReports } from './pages/reports.js';
import { renderCodeSigning, loadCodeSigning } from './pages/code-signing.js';
import { renderXcodeCloud, loadXcodeCloud } from './pages/xcode-cloud.js';
import { renderUsers, loadUsers } from './pages/users.js';
import { renderIris, loadIris } from './pages/iris.js';
import { renderSimulators, loadSimulators } from './pages/simulators.js';

const pageTitles = {
  dashboard: 'Dashboard', apps: 'Apps', versions: 'Versions', builds: 'Builds',
  testflight: 'TestFlight', submissions: 'Submissions', appinfo: 'App Info',
  screenshots: 'Screenshots', reviews: 'Customer Reviews', iap: 'In-App Purchases',
  subscriptions: 'Subscriptions', reports: 'Reports', codesigning: 'Code Signing',
  xcodecloud: 'Xcode Cloud', users: 'Users & Roles', iris: 'Iris (Private API)',
  simulators: 'Simulators',
};

const renderers = {
  dashboard: renderDashboard,
  apps: renderApps,
  versions: renderVersions,
  builds: renderBuilds,
  testflight: renderTestFlight,
  submissions: renderSubmissions,
  appinfo: renderAppInfo,
  screenshots: renderScreenshots,
  reviews: renderReviews,
  iap: renderIAP,
  subscriptions: renderSubscriptions,
  reports: renderReports,
  codesigning: renderCodeSigning,
  xcodecloud: renderXcodeCloud,
  users: renderUsers,
  iris: renderIris,
  simulators: renderSimulators,
};

const loaders = {
  dashboard: loadDashboard,
  apps: loadApps,
  versions: loadVersions,
  builds: loadBuilds,
  testflight: loadTestFlight,
  reviews: loadReviews,
  users: loadUsers,
  codesigning: loadCodeSigning,
  iap: loadIAP,
  subscriptions: loadSubscriptions,
  xcodecloud: loadXcodeCloud,
  iris: loadIris,
  simulators: loadSimulators,
};

export function navigate(page) {
  state.currentPage = page;
  document.querySelectorAll('.nav-item').forEach(el => {
    el.classList.toggle('active', el.dataset.page === page);
  });
  const title = pageTitles[page] || page;
  document.getElementById('pageTitle').textContent = title;
  document.getElementById('pageBreadcrumb').innerHTML = `<span>ASC Manager</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18l6-6-6-6"/></svg><span>${title}</span>`;
  renderPage(page);
}

export function renderPage(page) {
  const content = document.getElementById('content');
  const render = renderers[page];
  if (render) {
    content.innerHTML = render();
    const loader = loaders[page];
    if (loader) loader();
  }
}

export function refreshCurrentPage() {
  showToast('Refreshing...', 'info');
  renderPage(state.currentPage);
}

export function runAffordance(cmd) {
  showToast(cmd, 'info');
  logCommand(cmd);
}

// Setup nav click handlers
export function setupNavigation() {
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', () => navigate(btn.dataset.page));
  });
}

// Expose to window for inline onclick handlers
window.navigate = navigate;
window.refreshCurrentPage = refreshCurrentPage;
window.runAffordance = runAffordance;
